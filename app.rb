require 'sinatra'
require 'byebug'

enable :sessions

GARDEN_MOTOR_RELAY_PIN=11
BLIND_UP_RELAY_1_PIN=26
BLIND_DOWN_RELAY_1_PIN=24
LIGHT_INPUT_PIN=12

get '/' do
  erb :index
end

post '/relay' do
  redirect to('/')
end
