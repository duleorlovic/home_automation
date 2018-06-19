require 'sinatra/activerecord/rake'

namespace :db do
  task :load_config do
    require './app'
  end
end

namespace :temp do
  task :read do
    require './app'
    Temperature.create sensor: 'attic', celsius: TEMP_ATTIC.read
    Temperature.create sensor: 'living_room', celsius: TEMP_LIVING_ROOM.read
  end
end
