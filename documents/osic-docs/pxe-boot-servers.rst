====================
PXE boot the servers
====================

Gather MAC addresses
~~~~~~~~~~~~~~~~~~~~

In order to PXE boot your servers, you need to obtain the MAC address of the
network interface (For example, **p1p1**) that is configured to PXE boot on every
server. The MAC addresses must be mapped to their respective hostname.

#. Go to root home directory

   .. code:: console

      cd /root

#. Log into the LXC container and create a CSV file named ``ilo.csv``.

   .. note::
      
      Each line should have a hostname to assign for the server, its ILO IP
      address, type of node it will be (controller, logging, compute, cinder,
      swift). Ensure hostnames are meaningful to you, For example, `controller01`,
      and `controller02`.

#. Use the information from your onboarding email to create the CSV.
   We recommend that you specify three hosts as your controllers and
   at least three swift nodes if you decide to deploy swift as well.

   For example:

   .. code:: ini

      729427-controller01,10.15.243.158,controller
      729426-controller02,10.15.243.157,controller
      729425-controller03,10.15.243.156,controller
      729424-logging01,10.15.243.155,logging
      729423-logging02,10.15.243.154,logging
      729422-logging03,10.15.243.153,logging
      729421-compute01,10.15.243.152,compute
      729420-compute02,10.15.243.151,compute
      729419-compute03,10.15.243.150,compute
      729418-compute04,10.15.243.149,compute
      729417-compute05,10.15.243.148,compute
      729416-compute06,10.15.243.147,compute
      729415-compute07,10.15.243.146,compute
      729414-compute08,10.15.243.145,compute
      729413-cinder01,10.15.243.144,cinder
      729412-cinder02,10.15.243.143,cinder
      729411-cinder03,10.15.243.142,cinder
      729410-swift01,10.15.243.141,swift
      729409-swift02,10.15.243.140,swift
      729408-swift03,10.15.243.139,swift

   Remove any spaces in your CSV file. We recommend removing the deployment
   host you manually provisioned from this CSV so you do not accidentally
   reboot the host you are working from.

After the information collects, use this create another
CSV file to be the input for many different steps in the build
process.

Create input CSV
~~~~~~~~~~~~~~~~

#. Use the following script to create a CSV named ``input.csv`` in the
   following format:

   .. code::

      hostname,mac-address,host-ip,host-netmask,host-gateway,dns,pxe-interface,cobbler-profile

#. (Optional) If this will be an OpenStack-Ansible installation, we recommend
   ordering the rows in the CSV file in the following order:

   #. Controller nodes
   #. Logging nodes
   #. Compute nodes
   #. Cinder nodes
   #. Swift nodes

   An OpenStack-Ansible example installation:

   .. code:: ini

      744800-infra01.example.com,A0:36:9F:7F:70:C0,172.22.0.23,255.255.252.0,172.22.0.1,8.8.8.8,p1p1,ubuntu-14.04.3-server-unattended-osic-generic
      744819-infra02.example.com,A0:36:9F:7F:6A:C8,172.22.0.24,255.255.252.0,172.22.0.1,8.8.8.8,p1p1,ubuntu-14.04.3-server-unattended-osic-generic
      744820-infra03.example.com,A0:36:9F:82:8C:E8,172.22.0.25,255.255.252.0,172.22.0.1,8.8.8.8,p1p1,ubuntu-14.04.3-server-unattended-osic-generic
      744821-logging01.example.com,A0:36:9F:82:8C:E9,172.22.0.26,255.255.252.0,172.22.0.1,8.8.8.8,p1p1,ubuntu-14.04.3-server-unattended-osic-generic
      744822-compute01.example.com,A0:36:9F:82:8C:EA,172.22.0.27,255.255.252.0,172.22.0.1,8.8.8.8,p1p1,ubuntu-14.04.3-server-unattended-osic-generic
      744823-compute02.example.com,A0:36:9F:82:8C:EB,172.22.0.28,255.255.252.0,172.22.0.1,8.8.8.8,p1p1,ubuntu-14.04.3-server-unattended-osic-generic
      744824-cinder01.example.com,A0:36:9F:82:8C:EC,172.22.0.29,255.255.252.0,172.22.0.1,8.8.8.8,p1p1,ubuntu-14.04.3-server-unattended-osic-cinder
      744825-object01.example.com,A0:36:9F:7F:70:C1,172.22.0.30,255.255.252.0,172.22.0.1,8.8.8.8,p1p1,ubuntu-14.04.3-server-unattended-osic-swift
      744826-object02.example.com,A0:36:9F:7F:6A:C2,172.22.0.31,255.255.252.0,172.22.0.1,8.8.8.8,p1p1,ubuntu-14.04.3-server-unattended-osic-swift
      744827-object03.example.com,A0:36:9F:82:8C:E3,172.22.0.32,255.255.252.0,172.22.0.1,8.8.8.8,p1p1,ubuntu-14.04.3-server-unattended-osic-swift

The following script loops through each iLO IP address in ``ilo.csv`` to
obtain the MAC address of the network interface configured to PXE boot and
setup rest of information as well as shown above.

.. note::

   Make sure to set `COUNT` to the first usable address after
   deployment host and container. For example, if you use .2 and .3 for
   deployment and container, start with .4 controller1. 
   Make sure to change ``host-ip,host-netmask,host-gateway`` in the script
   (172.22.0.$COUNT,255.255.252.0,172.22.0.1) to match your PXE network
   configurations. If you later discover that you have configured the wrong
   IPs here, you need to restart from this point.

.. code:: ini

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

.. important::
  
   Before continuing, make sure the generated script
   ``input.csv`` has all the information as shown previously. If you
   run into some missing information, you may need to paste the above
   command in a bash script and execute it.

Assigning a Cobbler profile
~~~~~~~~~~~~~~~~~~~~~~~~~~~

The last column in the CSV file specifies which Cobbler profile to map
the Cobbler system to. You have the following options:

* ubuntu-14.04.3-server-unattended-osic-generic

  Typically, you will use the `ubuntu-14.04.3-server-unattended-osic-generic`
  Cobbler profile. It creates one RAID10 raid group. The operating system will
  see this as ``/dev/sda``.
  
* ubuntu-14.04.3-server-unattended-osic-generic-ssd
* ubuntu-14.04.3-server-unattended-osic-cinder

  The `ubuntu-14.04.3-server-unattended-osic-cinder` Cobbler profile
  creates one RAID1 raid group and a second RAID10 raid group. These
  will be seen by the operating system as ``/dev/sda`` and ``/dev/sdb``,
  respectively.
  
* ubuntu-14.04.3-server-unattended-osic-cinder-ssd
* ubuntu-14.04.3-server-unattended-osic-swift
  
  The `ubuntu-14.04.3-server-unattended-osic-swift` Cobbler profile
  creates one RAID1 raid group and 10 RAID0 raid groups each containing one
  disk. The HP storage controller does not present a disk to the operating
  system unless it is in a RAID group. Because swift needs to deal with
  individual, non-RAIDed disks, the only way to do this is to put each
  disk in its own RAID0 raid group.
  
* ubuntu-14.04.3-server-unattended-osic-swift-ssd

.. important::

   You will only use the `ssd` Cobbler profiles if the servers contain SSD drives.

Generate Cobbler systems
~~~~~~~~~~~~~~~~~~~~~~~~

The ``generate_cobbler_systems.py`` script will generate a list of
`cobbler system` commands to the standard output.

#. If you pipe the standard output to ``bash``, all the servers will be
   added to Cobbler (internally done by issuing a cobbler system command):

   .. code:: console

      cd /root/rpc-prep-scripts

      python generate_cobbler_system.py /root/input.csv | bash

#. Verify the `cobbler system` entries were added by running
   ``cobbler system list``.

#. Once all of the `cobbler systems` are setup, run the following command:

   .. code::

      cobbler sync

Begin PXE booting
~~~~~~~~~~~~~~~~~

#. Set the servers to boot from PXE on the next reboot and reboot all of the
   servers with the following command (if the deployment host is the first
   controller, you will want to remove it from the ``ilo.csv`` file so you do not
   reboot the host running the LXC container):

   .. code::

      for i in $(cat /root/ilo.csv)
      do
      NAME=$(echo $i | cut -d',' -f1)
      IP=$(echo $i | cut -d',' -f2)
      echo $NAME
      ipmitool -I lanplus -H $IP -U USERNAME -P PASSWORD chassis bootdev pxe
      sleep 1
      ipmitool -I lanplus -H $IP -U USERNAME -P PASSWORD power reset
      done

  .. note::

     If the servers are already shut down, we recommend you change
     `power reset` with `power on` in the above command.

After PXE booting, a call will be made to the cobbler API to ensure the server
does not PXE boot again.

#. Run the following command to see which servers are still set to PXE boot:

   .. code::

      for i in $(cobbler system list)
      do
      NETBOOT=$(cobbler system report --name $i | awk '/^Netboot/ {print $NF}')
      if [[ ${NETBOOT} == True ]]; then
      echo -e "$i: netboot_enabled : ${NETBOOT}"
      fi
      done

   Any server which returns ``True`` has not yet PXE booted. Rerun last
   command until there is no output to make sure all your servers has
   finished pxebooting. Time to wait depends on the number of servers you
   are deploying. If somehow, one or two servers did not go through for a
   long time, you may want to investigate them with their ILO console. In
   most cases, this is due to rebooting those servers either fails or
   hangs, so you may need to reboot them manually with ILO.

   .. note::

      In case you want to re-pxeboot servers, make sure to clean old
      settings from cobbler with the following command:

      .. code::

         for i in `cobbler system list`; do cobbler system remove --name $i; done;
