#!/bin/bash

export private_network="private-network"
export private_subnet="$private_network-subnet"
export image_name="testimage"
export image_file="cirros-0.3.5-x86_64-disk.img"
export flavor="m1.test"
export external_network="ext-net"
export external_subnet="$external_network-subnet"
export router_name="router0"
export keypair="test-key"

neutron net-create $external_network --router:external --provider:network_type flat \
    --provider:physical_network datacentre

neutron subnet-create --name $external_subnet --enable_dhcp=False \
    --allocation_pool start=192.168.24.50,end=192.168.24.59 \
    --gateway=192.168.24.1 $external_network 192.168.24.0/24

openstack network create $private_network
openstack subnet create --allocation-pool start=192.168.40.5,end=192.168.40.50 \
    --subnet-range 192.168.40.0/24 --network $private_network $private_subnet

openstack security group create test-sec-group
openstack security group rule create --protocol tcp --dst-port 22 test-sec-group
openstack security group rule create --protocol tcp --dst-port 80 test-sec-group

openstack router create $router_name
openstack router add subnet $router_name $private_subnet

neutron router-gateway-set $router_name $external_network

#openstack flavor create --ram 256 --disk 2 --vcpus 1 $flavor


#openstack image create --file $image_file  --container-format bare --disk-format raw $image_name



