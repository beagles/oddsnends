#!/bin/bash

set -eux 

sudo systemctl stop openstack-*
sudo systemctl stop neutron-*
sudo systemctl stop httpd
for d in glance heat ironic \`ironic-inspector\` keystone mistral neutron nova nova_api nova_cell0 nova_placement zaqar ; 
do 
    mysql -u root --password=`sudo hiera 'mysql::server::root_password'` -e "drop database $d;" ; 
done
