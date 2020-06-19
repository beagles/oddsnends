#!/bin/bash -x
private_network="servers"
image_name="cirros"
flavor_name="m1.test"
external_network_name="extnet"

source ~stack/overcloudrc

openstack flavor create --ram 256 --disk 2 --vcpus 1 $flavor_name
openstack flavor create --ram 2048 --disk 20 --vcpus 1 m1.small
openstack security group create servers-sec-group
openstack security group rule create --protocol tcp --dst-port 22 servers-sec-group
openstack security group rule create --protocol tcp --dst-port 80 servers-sec-group
openstack security group rule create --protocol icmp servers-sec-group
openstack security group rule create --protocol ipv6-icmp servers-sec-group

if [[ $(openstack keypair show cirros_key > /dev/null 2>&1; echo $?) -ne 0 ]]; then
    openstack keypair create --private-key ~/cirros.key cirros_key
fi

if [[ $(openstack image show $image_name > /dev/null 2>&1 ; echo $?) -ne 0 ]]; then
    echo uploading cirros image
    openstack image create --file ~/cirros-0.4.0-x86_64-disk.img --container-format bare --disk-format raw $image_name
fi
nova boot --key-name cirros_key --image $image_name --flavor $flavor_name --nic net-name=$private_network cirros
echo "Waiting 40s for boot..."
sleep 40
declare float_ip=$(openstack floating ip create $external_network_name -f value -c name)
openstack server add floating ip cirros $(eval "echo \$float_ip")
openstack server add security group cirros servers-sec-group

