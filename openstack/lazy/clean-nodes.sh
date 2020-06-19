#!/bin/bash
source stackrc
openstack baremetal node list | grep 'power.on' | awk -e '{print $2;}' | while read; 
do
    openstack baremetal node power off $REPLY
done
openstack baremetal node list | grep 'True\|False' | awk -e '{print $2;}' | while read; 
do
    openstack baremetal node undeploy $REPLY
done
openstack baremetal node list | grep 'True\|False' | awk -e '{print $2;}' | while read; 
do 
    openstack baremetal node delete $REPLY 
done
