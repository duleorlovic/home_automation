require 'sinatra'
require 'sinatra/reloader' if development?
require 'byebug'
require 'logger'
IS_RASPBERRY = system('uname -a | grep raspberrypi')
if IS_RASPBERRY
  require 'pi_piper'
else
  puts 'OK we are on local'
end

# check pin numbers with `gpio readall`
GARDEN_MOTOR_RELAY_PIN = 17 # BCM 17, wPi 0, Physical 11
BLIND_UP_RELAY_1_PIN = 7 # BCM 7, wPi 11, Physical 26
BLIND_DOWN_RELAY_1_PIN = 8 # BCM 8, wPi 10, Physical 24
LIGHT_INPUT_PIN = 18 # BCM 18, wPi 1, Physical 12
TEMERATURE_PIN = 4 # BCM 4, wPi 7, Physical 7
UP_DOWN_DURATION_IN_SECONDS = 2

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

enable :sessions

class MyPin
  def initialize(h)
    @h = h
    if IS_RASPBERRY
      @pin = PiPiper::Pin.new h
    end
  end

  def on
    # $logger.info "ON #{@h}"
    if IS_RASPBERRY
      @pin.on
    else
      $session["value#{@h[:pin]}"] = true
    end
  end

  def off
    # $logger.info "OFF #{@h}"
    if IS_RASPBERRY
      @pin.off
    else
      $session["value#{@h[:pin]}"] = false
    end
  end

  def read
    if IS_RASPBERRY
      @pin.read
    else
      $session["value#{@h[:pin]}"]
    end
  end
end

system 'gpio unexportall'
garden = MyPin.new pin: GARDEN_MOTOR_RELAY_PIN, direction: :out
blind_up = MyPin.new pin: BLIND_UP_RELAY_1_PIN, direction: :out
blind_down = MyPin.new pin: BLIND_DOWN_RELAY_1_PIN, direction: :out
_light = MyPin.new pin: LIGHT_INPUT_PIN, direction: :in

before do
  $session = session
end

get '/' do
  @garden = garden
  erb :index
end

post '/' do
  case params[:commit]
  when 'water-on'
    garden.on
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
  @garden = garden
  erb :index
end
