#!/bin/bash
set -x
workserver_path=/srv/workserver
mkdir $workserver_path
cp workserver.py $workserver_path

# Update the OS
apt-get -y update

# install Apache2 and git
apt-get -y remove libaprutil1
apt-get -y autoremove
apt-get -y update && apt-get -y install apache2 git

# write some HTML
git clone https://github.com/Moe277/AzureFoundationDemo-West
cp -Rv ./AzureFoundationDemo-West/* /var/www/html

# restart Apache
apachectl restart

# install python3-bottle 
apt-get -y install python3-bottle

# create a service
touch /etc/systemd/system/workserver.service
printf '[Unit]\nDescription=workServer Service\nAfter=rc-local.service\n' >> /etc/systemd/system/workserver.service
printf '[Service]\nWorkingDirectory=%s\n' $workserver_path >> /etc/systemd/system/workserver.service
printf 'ExecStart=/usr/bin/python3 %s/workserver.py\n' $workserver_path >> /etc/systemd/system/workserver.service
printf 'ExecReload=/bin/kill -HUP $MAINPID\nKillMode=process\nRestart=on-failure\n' >> /etc/systemd/system/workserver.service
printf '[Install]\nWantedBy=multi-user.target\nAlias=workserver.service' >> /etc/systemd/system/workserver.service
chmod +x /etc/systemd/system/workserver.service

systemctl start workserver

# restart Apache
apachectl restart

# create crontab entry to start service
# Method borrowed from https://stackoverflow.com/questions/878600/how-to-create-a-cron-job-using-bash/17975418#17975418
croncmd="systemctl start workserver"
cronjob="@reboot $croncmd"
( crontab -l | grep -v -F "$croncmd" ; echo "$cronjob" ) | crontab -
