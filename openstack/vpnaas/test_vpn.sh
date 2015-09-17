#!/bin/bash
set -x
set -e

IMAGE=cirros-0.3.4-x86_64-uec

# Create private network
neutron net-create privateA
neutron subnet-create --ip_version 4 --gateway 10.1.0.1 --name privateA privateA 10.1.0.0/24

# Create public network and external router
neutron router-create routerA
neutron router-interface-add routerA privateA

#neutron subnet-create --ip_version 4 --allocation-pool start=172.24.4.11,end=172.24.4.29 --gateway 172.24.4.10 --name public-subnet public 172.24.4.0/24 -- --enable_dhcp=False

# NOTE this version of neutron apparently doesn't support specifying fixed ip
# important that the peer addressess/id specified below reflects real IPs assigned
neutron router-gateway-set routerA public # --fixed-ip ip_address=172.24.4.11

# Create second private network
neutron net-create privateB
neutron subnet-create --ip_version 4 --gateway 10.2.0.1 --name privateB privateB 10.2.0.0/24

# Create a second router
neutron router-create routerB
neutron router-interface-add routerB privateB

# NOTE this version of neutron apparently doesn't support specifying fixed ip
# important that the peer addressess/id specified below reflects real IPs assignedx
neutron router-gateway-set routerB public # --fixed-ip ip_address=172.24.4.12


# Start a VM on each subnet
nova boot --flavor 1 --image ${IMAGE} --nic net-id=$(neutron net-show -fvalue -Fid privateA) peter
nova boot --flavor 1 --image ${IMAGE} --nic net-id=$(neutron net-show -fvalue -Fid privateB) paul


# Create VPN connections
neutron vpn-ikepolicy-create ikepolicy
neutron vpn-ipsecpolicy-create ipsecpolicy
neutron vpn-service-create --name myvpnA --description "My vpn serviceA" routerA privateA

neutron ipsec-site-connection-create --name vpnconnection1 --vpnservice-id myvpnA \
--ikepolicy-id ikepolicy --ipsecpolicy-id ipsecpolicy --peer-address 172.24.4.12 \
--peer-id 172.24.4.12 --peer-cidr 10.2.0.0/24 --psk secret

neutron vpn-service-create --name myvpnB --description "My vpn serviceB" routerB privateB

neutron ipsec-site-connection-create --name vpnconnection2 --vpnservice-id myvpnB \
--ikepolicy-id ikepolicy --ipsecpolicy-id ipsecpolicy --peer-address 172.24.4.11 \
--peer-id 172.24.4.11 --peer-cidr 10.1.0.0/24 --psk secret
