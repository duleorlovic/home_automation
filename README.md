# Home Automation

## Requirements to Run on Raspberry Pi

Sqlite3 on Rpi

~~~
sudo apt-get update; sudo apt-get -y dist-upgrade; sudo apt-get install sqlite3
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

DB

~~~
sudo rake db:migrate
~~~

To run at startup when device boots, create `.bash_profile`

~~~
# ~/.bash_profile
sudo ruby /home/pi/home_automation/app.rb -e production
~~~

To run scheduled task for temperature readings

~~~
rake temp:read
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

Set up keys on raspberry pi and download source from your comp

~~~
git clone orlovic@192.168.2.103:/home/orlovic/ruby/home_automation/.git
git reset --hard HEAD^ && git pull local master
sudo ruby app.rb
~~~

Run in crontab

~~~
*/3 * * * * curl http://192.168.1.6:4567 --data commit=water-on ; sleep 5 ; curl http://192.168.1.6:4567 --data commit=water-off >> /home/orlovic/Downloads/cron.log 2>&1
~~~
