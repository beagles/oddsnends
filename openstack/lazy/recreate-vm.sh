#!/bin/bash -x 
private_network="servers"
image_name="cirros"
flavor_name="m1.test"
external_network_name="extnet"

source ~stack/overcloudrc
openstack server create --wait --key-name cirros_key --image $image_name --flavor $flavor_name --network $private_network cirros
openstack server add security group cirros servers-sec-group

