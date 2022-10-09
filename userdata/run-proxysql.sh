#! /bin/bash

set -e
echo "Starting Consult Server"

sudo apt-get -y update
sudo apt-get -y install apache2


LOCAL_IP=`curl http://169.254.169.254/latest/meta-data/local-ipv4`

LOCAL_HOST=`curl http://169.254.169.254/latest/meta-data/instance-id`


sudo /opt/consul/bin/run-consul --client --cluster-tag-key consul-cluster --cluster-tag-value uat-cluster

/usr/local/bin/consul kv put proxysql/servers/$(LOCAL_HOST) $(LOCAL_IP)



sudo mkdir /opt/consul-template

cd /opt/consul-template

sudo wget https://releases.hashicorp.com/consul-template/0.19.4/consul-template_0.19.4_linux_amd64.zip

sudo unzip consul-template_0.19.4_linux_amd64.zip

sudo ln -s /opt/consul-template/consul-template /usr/local/bin/consul-template

sudo cat <<EOF | tee /opt/consul-template/templates/proxysql.ctmpl
DELETE FROM proxysql_servers;
{{range ls "proxysql/servers"}}
REPLACE INTO proxysql_servers (hostname, port, comment) VALUES
('{{.Value}}', 6032, '{{.Key}}');{{end}}
SAVE PROXYSQL SERVERS TO DISK;
LOAD PROXYSQL SERVERS TO RUNTIME;
EOF



sudo cat <<EOF | /opt/consul-template/config/consul-template.cfg
consul {
  auth {
    enabled = false
  }
  address = "uat-consul.internal:8500"
  retry {
    enabled = true
    attempts = 12
    backoff = "250ms"
    max_backoff = "1m"
  }
  ssl {
    enabled = false
  }
}
reload_signal = "SIGHUP"
kill_signal = "SIGINT"
max_stale = "10m"
log_level = "info"
wait {
  min = "5s"
  max = "10s"
}
template {
  source = "/opt/consul-template/templates/proxysql.ctmpl"
  destination = "/opt/consul-template/templates/proxysql.sql"
  command = "/bin/bash -c 'mysql --defaults-file=/etc/proxysql-admin.my.cnf < /opt/consul-template/templates/proxysql.sql'"
  command_timeout = "60s"
  perms = 0644
  backup = true
  wait = "2s:6s"
}
EOF




nohup /usr/local/bin/consul-template -config=/opt/consul-template/config/consul-template.cfg > /var/log/consul-template/consul-template.log 2>&1 &

## Now Lets Configure ProxySQL

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
)
#defines MySQL Query Rules
mysql_query_rules:
(
     {
        rule_id=1
        active=1
        match_pattern=" *_tmp_*"
        destination_hostgroup=1
        apply=1
        log=1
    },
    {
        rule_id=2
        active=1
        match_pattern="^(?i)CREATE "
        destination_hostgroup=1
        apply=1
        log=1
    },
    {
        rule_id=3
        active=1
        match_pattern="^(?i)INSERT "
        destination_hostgroup=1
        apply=1
        log=1
    },
    {
        rule_id=4
        active=1
        match_pattern="^(?i)SELECT .*_tmp_"
        destination_hostgroup=1
        apply=1
        log=1
    },
    {
        rule_id=5
        active=1
        match_pattern="^(?i)SELECT "
        destination_hostgroup=2
        apply=1
        log=1
    },
    {
        rule_id=6
        active=1
        match_pattern="^(?i)UPDATE "
        destination_hostgroup=1
        apply=1
        log=1
    },
    {
        rule_id=7
        active=1
        match_pattern="^(?i)DELETE "
        destination_hostgroup=1
        apply=1
        log=1
    },
    {
        rule_id=8
        active=1
        match_pattern="*"
        destination_hostgroup=1
        apply=1
        log=1
    },

)
EOF




sudo systemctl enable proxysql
sudo systemctl restart proxysql
