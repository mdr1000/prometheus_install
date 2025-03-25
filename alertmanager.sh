#!/bin/bash

#-----------------------------------------------------------------
# Script to install Alertmanager on Linux Ubuntu 24.04
# Developed by Damir Mullagaliev in 2025
#-----------------------------------------------------------------

ALERTMANAGER_VERSION="0.28.0"
ALERTMANAGER_FOLDER_CONFIG=/etc/alertmanager
ALERTMANAGER_FOLDER_TSDATA=/etc/alertmanager/data

cd /tmp
wget https://github.com/prometheus/alertmanager/releases/download/v$ALERTMANAGER_VERSION/alertmanager-$ALERTMANAGER_VERSION.linux-amd64.tar.gz
tar xvfz alertmanager-$ALERTMANAGER_VERSION.linux-amd64.tar.gz
cd alertmanager-$ALERTMANAGER_VERSION.linux-amd64

mv alertmanager /usr/bin/
rm -rf /tmp/alertmanager*

mkdir -p $ALERTMANAGER_FOLDER_CONFIG
mkdir -p $ALERTMANAGER_FOLDER_TSDATA


cat <<EOF> $ALERTMANAGER_FOLDER_CONFIG/alertmanager.yml
global:
  resolve_timeout: 1m

route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'email'
receivers:
  - name: 'email'
    email_configs:
    - to: alert-mdr1000@yandex.ru
      from: alert-mdr1000@yandex.ru
      smarthost: smtp.yandex.ru:587
      auth_username: alert-mdr1000
      auth_identity: alert-mdr1000
      auth_password: bnuhotqvehnthrbs
      send_resolved: true

inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'dev', 'instance']
EOF


useradd -rs /bin/false alertmanager
chown alertmanager:alertmanager /usr/bin/alertmanager
chown alertmanager:alertmanager $ALERTMANAGER_FOLDER_CONFIG
chown alertmanager:alertmanager $ALERTMANAGER_FOLDER_CONFIG/alertmanager
chown alertmanager:alertmanager $ALERTMANAGER_FOLDER_TSDATA


cat <<EOF> /etc/systemd/system/alertmanager.service
[Unit]
Description=Alertmanager
After=network.target

[Service]
User=alertmanager
Group=alertmanager
Type=simple
ExecStart=/usr/bin/alertmanager \
--config.file=$ALERTMANAGER_FOLDER_CONFIG/alertmanager.yml \
--storage.path=$ALERTMANAGER_FOLDER_TSDATA \
--cluster.advertise-address=[_____________:9093]
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure

[Install]
WantedBy=multi-user.target
damir@prometheus:/etc/alertmanager$
EOF

systmctl daemon-reload
systemctl start alertmanager
systemctl enable alertmanager
systemctl status alertmanager --no-pager
alertmanager --version