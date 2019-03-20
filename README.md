# Home Automation

## Development

```
bundle exec ruby app.rb
```

## Requirements to Run on Raspberry Pi

Sqlite3 on Rpi

~~~
sudo apt-get update; sudo apt-get -y dist-upgrade
sudo apt-get install ruby ruby-dev
sudo apt-get install git vim sqlite3 libsqlite3-dev
sudo apt-get install npm
~~~

Code and dependencies

~~~
git clone https://github.com/duleorlovic/home_automation.git
cd home_automation
bundle install
cd public
npm install
cd -
~~~

DB prepare. We need sudo since rake tasks need to load pi_piper and all pins

~~~
sudo bundle exec rake db:create
sudo bundle exec rake db:migrate
~~~

To run Sinatra server use

~~~
sudo bundle exec ruby app.rb
~~~

To run at startup when device boots, create `.bash_profile`

~~~
# ~/.bash_profile
sudo ruby /home/pi/home_automation/app.rb -e production
~~~

To run scheduled task for temperature readings

~~~
0 * * * * cd home_automation ; rake temp:read >> log/cron.log 2>&1
~~~

Watch logs

~~~
tail -f /home/pi/home_automation/log/production.log
~~~

Check if it is running

~~~
ps aux | grep home_automation
~~~

## Development on Pi

Push with a force

~~~
git add . &&  git commit --amend --no-edit && git push -f
~~~

and download with hard reset

~~~
git reset --hard HEAD^ && git pull
sudo ruby app.rb
~~~

# Cron jobs

For temperature reading

~~~
# crontab
# every hour at 50min
50 * * * * cd home_automation ; sudo rake temp:read >> log/cron.log 2>&1
~~~

Run in crontab on host

~~~
*/3 * * * * curl http://192.168.1.6:4567 --data commit=water-on ; sleep 5 ; curl http://192.168.1.6:4567 --data commit=water-off >> /home/orlovic/Downloads/cron.log 2>&1
~~~
