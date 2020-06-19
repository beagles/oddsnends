#!/bin/bash -x 
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
fi
if [[ $(openstack security group show servers-sec-grp > /dev/null; echo $?) -eq 1 ]]; then
        echo creating security group for servers
        openstack security group create servers-sec-grp -f value -c id
fi

if [[ $(openstack security group rule list servers-sec-grp --protocol tcp --ingress -f value 2>&1  | grep "0.0.0.0/0 22:22") == "" ]]; then
        echo opening SSH for security group
        openstack security group rule create --protocol tcp --dst-port 22 servers-sec-grp
fi

if [[ $(openstack security group rule list servers-sec-grp --protocol tcp --ingress -f value 2>&1  | grep "0.0.0.0/0 80:80") == "" ]]; then
        echo opening HTTP for security group
        openstack security group rule create --protocol tcp --dst-port 80 servers-sec-grp
fi

if [[ $(openstack router show ${private_network}-router > /dev/null 2>&1 ; echo $?) -ne 0 ]]; then
        echo creating router for private network
        openstack router create ${private_network}-router
fi
router_id=$(openstack router show ${private_network}-router -f value -c id)
subnet_id=$(openstack subnet show ${private_network}-subnet -f value -c id)
port_list=$(neutron router-port-list $router_id -f value -c fixed_ips)
if [[ -z $port_list || (! -z $port_list && $(echo $port_list | sed "s/u'/'/g" | sed "s/'/\"/g" | jq ".[0][\"subnet_id\"]" | tr '"' "\0") != $subnet_id) ]]; then
        echo connecting downlink for our servers network
        openstack router add subnet ${private_network}-router ${private_network}-subnet
fi
echo connect the servers router to the external network
neutron router-gateway-set ${private_network}-router $external_network_name

if [[ $(openstack flavor show $flavor_name > /dev/null 2>&1 ; echo $?) -ne 0 ]]; then
        echo creating flavor
        openstack flavor create  --ram 256 --disk 2 --vcpus 1 $flavor_name
fi
if [[ $(openstack image show $image_name > /dev/null 2>&1 ; echo $?) -ne 0 ]]; then
        echo uploading cirros image
        if [[ ! -f ~/data/cirros-0.3.5-x86_64-disk.img ]]; then
                curl -o ~/data/cirros-0.3.5-x86_64-disk.img http://download.cirros-cloud.net/0.3.5/cirros-0.3.5-x86_64-disk.img
        fi
        openstack image create --file ~/data/cirros-0.3.5-x86_64-disk.img --container-format bare --disk-format raw $image_name
fi

for i in $(seq 1 3); do
        if [[ $(openstack server show cirros${i} > /dev/null 2>&1 ; echo $?) -ne 0 ]]; then
                echo create cirros${i}
                openstack server create --wait --image $image_name --flavor $flavor_name --network $private_network cirros${i}
                echo creating floating ips
                declare float_ip_${i}=$(openstack floating ip create $external_network_name -f value -c name)
                echo connecting cirros${i} to floating ip
                openstack server add floating ip cirros${i} $(eval "echo \$float_ip_${i}")
                openstack server add security group cirros${i} servers-sec-grp
        fi
done

