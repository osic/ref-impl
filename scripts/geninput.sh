#!/bin/bash

# Set count to the first usable address after deployment host and container
# ex. If you use .2 and .3 for deployment and container, start with .4 (controller1)
COUNT=23

for i in $(cat ilo.csv)
do
    NAME=`echo $i | cut -d',' -f1`
    IP=`echo $i | cut -d',' -f2`
    TYPE=`echo $i | cut -d',' -f3`

    case "$TYPE" in
        cinder)
            SEED='ubuntu-14.04.3-server-unattended-osic-cinder'
            ;;
        swift)
            SEED='ubuntu-14.04.3-server-unattended-osic-swift'
            ;;
        *)
            SEED='ubuntu-14.04.3-server-unattended-osic-generic'
            ;;
    esac
    MAC=`sshpass -p calvincalvin ssh -o StrictHostKeyChecking=no root@$IP show /system1/network1/Integrated_NICs | grep Port1 | cut -d'=' -f2`
    #hostname,mac-address,host-ip,host-netmask,host-gateway,dns,pxe-interface,cobbler-profile
    echo "$NAME,${MAC//[$'\t\r\n ']},172.22.0.$COUNT,255.255.252.0,172.22.0.1,8.8.8.8,p1p1,$SEED" | tee -a input.csv

    (( COUNT++ ))
done
