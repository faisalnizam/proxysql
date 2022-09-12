#! /bin/bash

echo "========================="
echo "Server For ProxySQL"
echo "========================="


sudo wget https://github.com/sysown/proxysql/releases/download/v2.2.0/proxysql_2.2.0-ubuntu20_amd64.deb
sudo dpkg -i proxysql_2.2.0-ubuntu20_amd64.deb

sudo apt-get install -y lsb-release mysql-client
sudo wget -O - 'https://repo.proxysql.com/ProxySQL/repo_pub_key' | apt-key add -
sudo echo deb https://repo.proxysql.com/ProxySQL/proxysql-2.2.x/$(lsb_release -sc)/ ./ | tee /etc/apt/sources.list.d/proxysql.list
sudo apt-get update
sudo mv /etc/proxysql.cnf /etc/proxysql.cnf.orig

sudo cat <<EOF | tee /etc/proxysql.cnf
datadir="/var/lib/proxysql"
admin_variables =
{
        admin_credentials="admin:Admin321@;cluster1:@T!@#$%;master:logincluster"
        mysql_ifaces="0.0.0.0:6032"
        cluster_username="cluster1"
        cluster_password=""
        cluster_check_interval_ms=200
        cluster_check_status_frequency=100
        cluster_mysql_query_rules_save_to_disk=true
        cluster_mysql_servers_save_to_disk=true
        cluster_mysql_users_save_to_disk=true
        cluster_proxysql_servers_save_to_disk=true
        cluster_mysql_query_rules_diffs_before_sync=3
        cluster_mysql_servers_diffs_before_sync=3
        cluster_mysql_users_diffs_before_sync=3
        cluster_proxysql_servers_diffs_before_sync=3
        debug=true
        web_enabled=true
        stats_credentials="stats:admin"
        restapi_enabled=true
}
mysql_variables=
{
  threads=4
  max_connections=2048
  default_query_delay=0
  default_query_timeout=36000000
  have_compress=true
  poll_timeout=10000
  interfaces="0.0.0.0:6033;/tmp/proxysql.sock"
  default_schema="information_schema"
  stacksize=1048576
  server_version="8.0.25"
  connect_timeout_server=10000
  monitor_username="root"
  monitor_password=""
  monitor_history=600000
  monitor_connect_interval=5000
  monitor_ping_interval=2000
  monitor_read_only_interval=1500
  monitor_read_only_timeout=50000
  ping_interval_server_msec=15000
  ping_timeout_server=5000
  commands_stats=true
  sessions_sort=true
  connect_retries_on_failure=10
  set_query_lock_on_hostgroup=false
}
# defines all the MySQL servers
mysql_servers =
(
 { address="" , port=3306 , hostgroup=1, max_connections=100 }, // DB URL Write
 { address="" , port=3306 , hostgroup=2, max_connections=100 }, // DB URL Reader
)
# defines all the MySQL users
mysql_users:
(
    { username = "root" , password = "" , default_hostgroup = 1 , active = 1 }, // above mentioned DBs UN and PW
   # { username = "root" , password = "" , default_hostgroup = 1 , active = 1 }, // above mentioned DBs UN and PW
)
#defines MySQL Query Rules
mysql_query_rules:
(
    {
        rule_id=1
        active=1
        match_pattern="^(?i)CREATE "
        destination_hostgroup=1
        apply=1
        log=1
    },
    {
        rule_id=2
        active=1
        match_pattern="^(?i)INSERT "
        destination_hostgroup=1
        apply=1
        log=1
    },
    {
        rule_id=3
        active=1
        match_pattern="^(?i)SELECT .*_tmp_"
        destination_hostgroup=1
        apply=1
        log=1
    },
    {
        rule_id=4
        active=1
        match_pattern="^(?i)SELECT "
        destination_hostgroup=2
        apply=1
        log=1
    },
    {
        rule_id=5
        active=1
        match_pattern="^(?i)UPDATE "
        destination_hostgroup=1
        apply=1
        log=1
    },
    {
        rule_id=6
        active=1
        match_pattern="^(?i)DELETE "
        destination_hostgroup=1
        apply=1
        log=1
    },
)
proxysql_servers =
(
    {
        hostname="172.31.96.100"
        port=6032
        comment="proxysql130"
    },
    {
        hostname="172.31.128.100"
        port=6032
        comment="proxysql131"
    }
)
EOF


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
      __path__: /var/lib/proxysql/proxysql.log
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
