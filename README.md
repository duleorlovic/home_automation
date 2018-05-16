# Home Automation

## Run on Raspberry Pi

~~~
git clone https://github.com/duleorlovic/home_automation.git
~~~

To run at startup when device boots, create `.bash_profile`
~~~
# ~/.bash_profile
sudo ruby /home/pi/home_automation/app.rb -e production
~~~

Watch logs

~~~
tail -f /home/pi/home_automation/log/production.log
~~~

Check if it running

~~~
ps aux | grep home_automation
~~~

## Development

Set up keys on raspberry pi and download source from your comp

~~~
git clone orlovic@192.168.2.103:/home/orlovic/ruby/home_automation/.git
git reset --hard HEAD^ && git pull local master
sudo ruby app.rb
~~~
