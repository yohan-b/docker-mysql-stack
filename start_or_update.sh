#!/bin/bash
test -z $1 || HOST="_$1"
test -z $2 || INSTANCE="_$2"
test -f ~/secrets.tar.gz.enc || curl -o ~/secrets.tar.gz.enc "https://cloud.scimetis.net/s/${KEY}/download?path=%2F&files=secrets.tar.gz.enc"
openssl enc -aes-256-cbc -d -in ~/secrets.tar.gz.enc | tar -zxv --strip 2 secrets/docker-mysql-stack${HOST}${INSTANCE}/crontab secrets/docker-mysql-stack${HOST}${INSTANCE}/debian.cnf
sudo chown root. crontab debian.cnf
sudo chmod 644 crontab
# --force-recreate is used to recreate container when crontab file has changed
unset VERSION_MYSQL VERSION_CRON
VERSION_MYSQL=$(git ls-remote ssh://git@git.scimetis.net:2222/yohan/docker-mysql.git| head -1 | cut -f 1|cut -c -10) \
VERSION_CRON=$(git ls-remote ssh://git@git.scimetis.net:2222/yohan/docker-cron.git| head -1 | cut -f 1|cut -c -10) \
 sudo -E bash -c 'docker-compose up -d --force-recreate'
# We cannot remove the secrets files or restarting the container would become impossible
#rm -f crontab debian.cnf
