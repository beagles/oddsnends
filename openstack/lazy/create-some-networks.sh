#!/bin/bash -x 

set -eux
private_network="servers"
keypair_name="undercloud-stack"
image_name="cirros-0.3.5-x86_64"
flavor_name="m1.cirros"
external_network_name="extnet"

source ~stack/overcloudrc

#==========
#Networking
#==========

if [[ $(openstack network show $external_network_name > /dev/null 2>&1 ; echo $?) -ne 0 ]]; then
    echo create external network
    neutron net-create $external_network_name --router:external --provider:network_type flat --provider:physical_network datacentre
fi
if [[ $(openstack subnet show ${external_network_name}-subnet > /dev/null 2>&1 ; echo $?) -ne 0 ]]; then
    echo create external network subnet
    neutron subnet-create --name ${external_network_name}-subnet --enable_dhcp=False --allocation-pool=start=192.168.24.50,end=192.168.24.59 --gateway=192.168.24.1 $external_network_name 192.168.24.0/24
fi

#openstack network create --disable-port-security $private_network
if [[ $(openstack network show $private_network > /dev/null 2>&1 ; echo $?) -ne 0 ]]; then
    echo creating private network
    openstack network create $private_network
fi
if [[ $(openstack subnet show ${private_network}-subnet > /dev/null 2>&1 ; echo $?) -ne 0 ]]; then
    echo creating private network subnet
    openstack subnet create --allocation-pool start=192.168.40.5,end=192.168.40.50 --subnet-range 192.168.40.0/24 --network $private_network ${private_network}-subnet
    openstack subnet pool create --pool-prefix 2001:DB8:1234::/48 --default-prefix-length 64 --min-prefix-length 64 --max-prefix-length 64 subnet-pool-ipv6
    openstack subnet create --network=servers --subnet-pool subnet-pool-ipv6 --ip-version=6 --ipv6-address-mode=slaac --ipv6-ra-mode=slaac servers-v6-subnet
fi

if [[ $(openstack router show ${private_network}-router > /dev/null 2>&1; echo $?) -ne 0 ]]; then
    echo creating router
    openstack router create  --ha ${private_network}-router
    echo connect the servers router to the external network
    neutron router-gateway-set ${private_network}-router $external_network_name
fi

router_id=$(openstack router show ${private_network}-router -f value -c id)
subnet_id=$(openstack subnet show ${private_network}-subnet -f value -c id)
port_list=$(neutron router-port-list $router_id -f value -c fixed_ips)
if [[ -z $port_list || (! -z $port_list && $(echo $port_list | sed "s/u'/'/g" | sed "s/'/\"/g" | jq ".[0][\"subnet_id\"]" | tr '"' "\0") != $subnet_id) ]]; then
    echo connecting downlink for our servers network
    openstack router add subnet ${private_network}-router ${private_network}-subnet
    openstack router add subnet ${private_network}-router ${private_network}-v6-subnet
fi
