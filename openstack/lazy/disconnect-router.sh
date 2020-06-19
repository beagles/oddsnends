#!/bin/bash
private_network="servers"
keypair_name="undercloud-stack"
image_name="cirros-0.3.5-x86_64"
flavor_name="m1.cirros"
external_network_name="extnet"

source ~stack/overcloudrc

rt=${private_network}-router


openstack router remove subnet $rt ${private_network}-subnet
openstack router remove subnet $rt ${private_network}-v6-subnet
neutron router-gateway-clear $rt
openstack router delete $rt

