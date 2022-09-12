#! /bin/bash 
#################################
# THIS FILE IS NOT RUN
#################################



echo "========================="
echo "Servers For ProxySQL" 
echo "========================="



sudo apt-get install -y lsb-release mysql-client
sudo wget -O - 'https://repo.proxysql.com/ProxySQL/repo_pub_key' | apt-key add -
sudo echo deb https://repo.proxysql.com/ProxySQL/proxysql-2.2.x/$(lsb_release -sc)/ ./ | tee /etc/apt/sources.list.d/proxysql.list
sudo apt-get update
sudo mv /etc/proxysql.cnf /etc/proxysql.cnf.orig


sudo systemctl enable proxysql 
sudo systemctl restart proxysql 


echo "================"
echo "Promtail logging" 
echo "================"

sudo apt install unzip
sudo mkdir -p /data/loki

curl -s https://api.github.com/repos/grafana/loki/releases/latest | grep browser_download_url |  cut -d '"' -f 4 | grep promtail-linux-amd64.zip | wget -i -
unzip promtail-linux-amd64.zip
sudo mv promtail-linux-amd64 /usr/local/bin/promtail

sudo tee /etc/promtail-local-config.yaml<<EOF
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /data/loki/positions.yaml

clients:
  - url: http://loki.eyewa.internal:3100/loki/api/v1/push

scrape_configs:
- job_name: system
  static_configs:
  - targets:
      - localhost
    labels:
      job: varlogs
      __path__: /var/log/*log
- job_name: proxysql
  static_configs:
  - targets:
      - localhost
    labels:
      job: proxysql
      __path__: /var/lib/proxysql/*log
EOF

sudo tee /etc/systemd/system/promtail.service<<EOF
[Unit]
Description=Promtail service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/promtail -config.file /etc/promtail-local-config.yaml

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable promtail
sudo systemctl restart promtail
