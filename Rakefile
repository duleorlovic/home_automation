require 'sinatra/activerecord/rake'

namespace :db do
  task :load_config do
    require './app'
  end
end

namespace :temp do
  task :read do
    require './app'
    t1 = OneWire.new TEMPERATURE_FILE
    Temperature.create sensor: TEMPERATURE_FILE, celsius: t1.read
  end
end
