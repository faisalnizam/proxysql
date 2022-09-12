#! /bin/bash 

set -e

echo "Starting Consult Server" 

sudo apt-get -y update 
sudo apt-get -y install apache2 
#sudo systemctl restart apache2 


exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

sudo /opt/consul/bin/run-consul --server --cluster-tag-key consul-cluster --cluster-tag-value uat-cluster 

sudo wget https://github.com/openark/orchestrator/releases/download/v3.2.6/orchestrator_3.2.6_amd64.deb
sudo dpkg -i orchestrator_3.2.6_amd64.deb 

sudo cat <<EOF | tee /etc/orchestrator.conf.json
"KVClusterMasterPrefix": "mysql/master",
"ConsulAddress": "127.0.0.1:8500",
EOF

sudo service orchestrator restart 
sudo /usr/local/orchestrator/resources/bin/orchestrator-client -c submit-masters-to-kv-stores


# Prepare ProxySQL Configuration Directories 
sudo mkdir -p /etc/consul.d



