# rubocop:disable Style/GlobalVars
require 'sinatra'
require 'sinatra/activerecord'
require 'sinatra/reloader' if development?
require 'byebug'
require 'logger'
require_relative 'my_mail'
IS_RASPBERRY = system('uname -a | grep raspberrypi')
if IS_RASPBERRY
  require 'pi_piper'
else
  puts 'OK we are on local'
end

# check pin numbers with `gpio readall`
# GARDEN_MOTOR_RELAY_PIN - 1K - pin2 Base BC547,
# pin1 Collector BC547 - white_relay left,
# pin3 Emitter BC547 - GND, white_relay right - 3.3V pin1 Rpi,
# white_relay left - 1n4007 - white_relay right
# white_relay should connect brown 220V
GARDEN_MOTOR_RELAY_PIN = 17 # BCM 17, wPi 0, Physical 11
BLIND_DOWN_RELAY_1_PIN = 7 # BCM 7, wPi 11, Physical 26
BLIND_UP_RELAY_1_PIN = 8 # BCM 8, wPi 10, Physical 24
# 220V light - DC_adapter 3V, plus DC_adapter - LIGHT_INPUT_PIN, minus
# DC_adapter - GND
LIGHT_INPUT_PIN = 18 # BCM 18, wPi 1, Physical 12
# TEMPERATURE_PIN - pin2 temp_connector, pin1 temp_connector - pin1 3.3v Rpi,
# pin3 temp_connector - GND
# you can connect as many temp sensors as you like, reading from files
TEMPERATURE_PIN = 4 # BCM 4, wPi 7, Physical 7
ATTIC_TEMP_FILE = '/sys/bus/w1/devices/28-000004e4793a/w1_slave'.freeze
LIVING_ROOM_TEMP_FILE = '/sys/bus/w1/devices/28-000004e41fff/w1_slave'.freeze
# water_flow middle output - WATER_FLOW_PIN  no need for voltage divider since
# it is small current, water_flow left - 5V Rpi, water_flow right - GND
WATER_FLOW_PIN = 27 # BCM 27, wPi 2, Physical 13

UP_DOWN_DURATION_IN_SECONDS = 12

# http://recipes.sinatrarb.com/p/middleware/rack_commonlogger
# configure do
#   # logging is enabled by default in classic style applications,
#   # so `enable :logging` is not needed
#   # create folder `mkdir log` and gitignore with `touch log/.keep`
#   # file = File.new("#{settings.root}/log/#{settings.environment}.log", 'a+')
#   # file.sync = true
#   use Rack::CommonLogger, file
# end

# https://stackoverflow.com/questions/5995854/logging-in-sinatra
configure :production do
  $logger = Logger.new("#{settings.root}/log/common.log", 'hourly')
  $logger.level = Logger::WARN

  # Spit stdout and stderr to a file during production
  # in case something goes wrong
  $stdout.reopen("#{settings.root}/log/#{settings.environment}.log", 'w')
  $stdout.sync = true
  $stderr.reopen($stdout)
end

configure :development do
  $logger = Logger.new(STDOUT)
end

# to be able to access from other computers, or run with `ruby app.rb -o 0.0.0.0
set :bind, '0.0.0.0'
set :database, adapter: 'sqlite3', database: "#{__dir__}/db/home_automation.sqlite3"

enable :sessions

# this is used as fake pin
class MyPin
  def initialize(attr)
    @attr = attr
    @pin = PiPiper::Pin.new attr if IS_RASPBERRY
  end

  def on
    # $logger.info "ON #{@attr}"
    if IS_RASPBERRY
      @pin.on
    else
      $session["value#{@attr[:pin]}"] = true
    end
    Log.create text: 'water-on', color: 'info'
  end

  def off(message: nil, color: nil)
    # $logger.info "OFF #{@attr}"
    if IS_RASPBERRY
      @pin.off
    else
      $session["value#{@attr[:pin]}"] = false
    end
    Log.create text: "water-off #{message}", color: color || 'warning'
  end

  def read
    if IS_RASPBERRY
      @pin.read == 1
    else
      $session["value#{@attr[:pin]}"]
    end
  end
end

# this is used as fake 1-wire reading
class OneWire
  attr_accessor :file_name
  def initialize(file_name)
    @file_name = file_name
  end

  def read
    reading = if IS_RASPBERRY
                File.exist?(@file_name) && File.read(@file_name)
              else
                sample_reading
              end
    convert_to_number reading
  end

  def convert_to_number(reading)
    return 'temperature_not_available' if reading.blank?

    temp = reading.split('t=').last
    return 'temperature_not_proper_format' unless temp

    temp.strip.to_f / 1_000
  end

  def sample_reading
    <<~FILE
      08 02 4b 46 7f ff 08 10 a3 : crc=a3 YES
      08 02 4b 46 7f ff 08 10 a3 t=32500
    FILE
  end
end

# this is used to detect water flow
class WaterFlow
  MEASUREMENT_COUNT = 200
  def initialize
    @pin = MyPin.new pin: WATER_FLOW_PIN, direction: :in, pull: :up
  end

  def reading
    last_reading = @pin.read
    count = 0
    t = Time.now.to_f
    MEASUREMENT_COUNT.times do
      reading = @pin.read
      next if last_reading == reading

      last_reading = reading
      count += 1
    end
    # we should measure the time and use coeficient to get liters
    calculate(count, Time.now.to_f - t)
  end

  # coeficient if 4.8 ie if frequency is 48Hz than flow is = 48/4.8 = 10L/min
  def calculate(count, elapsed_time)
    return -1 if elapsed_time.zero?

    coeficient = 4.8
    (count.to_f / elapsed_time) / coeficient
  end
end

system 'gpio unexportall'
garden = MyPin.new pin: GARDEN_MOTOR_RELAY_PIN, direction: :out
blind_up = MyPin.new pin: BLIND_UP_RELAY_1_PIN, direction: :out
blind_down = MyPin.new pin: BLIND_DOWN_RELAY_1_PIN, direction: :out
_light = MyPin.new pin: LIGHT_INPUT_PIN, direction: :in
TEMP_ATTIC = OneWire.new ATTIC_TEMP_FILE
TEMP_LIVING_ROOM = OneWire.new LIVING_ROOM_TEMP_FILE
water_flow = WaterFlow.new

# rubocop:disable Rails/ApplicationRecord
# temperatures are reading in rake file
class Temperature < ActiveRecord::Base
end

class Log < ActiveRecord::Base
end
# rubocop:enable Rails/ApplicationRecord

before do
  $session = session
  @garden = garden
  @water_flow = water_flow
  @temperatures = Temperature.all.last 100
end

get '/' do
  erb :index
end

get '/temperature' do
  erb :temperature
end

get '/logs' do
  erb :logs
end

# rubocop:disable Metrics/BlockLength
post '/' do
  case params[:commit]
  when 'water-on'
    garden.on
    # rubocop:disable Rails/TimeZone
    current_time = Time.now
    # rubocop:enable Rails/TimeZone
    Thread.new do
      if params[:disable_check] != '1' && sleep(1) && @water_flow.reading < 1
        text = "SHUT DOWN water since reading is #{@water_flow.reading}"
        garden.off message: text, color: 'danger'
        MyMail.send subject: "[home_automation] water_flow.reading is zero #{current_time}", text: text
      elsif params[:minutes].to_i.positive?
        sleep params[:minutes].to_i.minutes
        garden.off message: "#{params[:minutes].to_i}.minutes elapsed from #{current_time}"
      end
    end
  when 'water-off'
    garden.off
  when 'UP'
    blind_up.on
    sleep UP_DOWN_DURATION_IN_SECONDS
    blind_up.off
  when 'DOWN'
    blind_down.on
    sleep UP_DOWN_DURATION_IN_SECONDS
    blind_down.off
  end
  logger.info params
  # erb :index
  redirect to '/?autorefresh=true'
end
# rubocop:enable Metrics/BlockLength
# rubocop:enable Style/GlobalVars
