=============================
Configuring the LXC container
=============================

Ensure the following configuration changes are made to the
pre-packaged LXC container.

#. Attach the LXC container:

   .. code::

      $ lxc-attach --name osic-prep

#. If you had to change the IP address above, reconfigure the DHCP server
   by running the following sed commands. You will need to change
   ``172.22.0.22`` to match the IP address you set above:

   .. code::

      sed -i '/^next_server: / s/ .*/ 172.22.0.22/' /etc/cobbler/settings

      sed -i '/^server: / s/ .*/ 172.22.0.22/' /etc/cobbler/settings

#. Open ``/etc/cobbler/dhcp.template`` and reconfigure your DHCP settings.

#. Change the ``subnet``, ``netmask``, ``option routers``,
   ``option subnet-mask``, and ``range dynamic-bootp`` parameters to match
   your network.

   .. code::

      subnet 172.22.0.0 netmask 255.255.252.0 {
           option routers             172.22.0.1;
           option domain-name-servers 8.8.8.8;
           option subnet-mask         255.255.252.0;
           range dynamic-bootp        172.22.0.23 172.22.0.200;
           default-lease-time         21600;
           max-lease-time             43200;
           next-server                $next_server;

#. Restart Cobbler and sync it:

   .. code::

      $ service cobbler restart

      $ cobbler sync

You can now PXE boot any servers, but it is still a manual
process. In order for it to be an automated process, a CSV file needs to
be created.

PXE boot the servers
~~~~~~~~~~~~~~~~~~~~

The following steps detail how to gather MAC addresses.

#. Go to root home directory:

   .. code::

      $ cd /root

#. Obtain the MAC address of the network interface configured to PXE boot on
   every server. For example, ``p1p1``.

#. Map the MAC addresses to their respective hostname by logging into the
   LXC container and creating a CSV file named ``ilo.csv``. Use the information
   from your onboarding email to create the CSV.

   For example:

   .. code:: 

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

   Ensure to remove any spaces in your CSV file. We recommend
   removing the deployment host you manually provisioned from this CSV so
   you do not accidentally reboot the host you are working from.

Once this information is collected, it will be used to create another
CSV file that will be the input for many different steps in the build
process.

Create input CSV
~~~~~~~~~~~~~~~~

Use the following script to create a CSV named ``input.csv`` in the
following format.

.. code::

   hostname,mac-address,host-ip,host-netmask,host-gateway,dns,pxe-interface,cobbler-profile

If you are installing OpenStack-Ansible, we recommended ordering the rows
in the CSV file in the following order:
   
 * Controller nodes
 * Logging nodes
 * Compute nodes
 * Cinder nodes
 * Swift nodes

An example for OpenStack-Ansible installations:

.. code::
   
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

The following command loops through each iLO IP address in ``ilo.csv``.
It obtains the MAC address of the network interface configured to PXE boot
and setup the rest of information as well as shown above:

.. note::
   
   Ensure to set ``COUNT`` to the first usable address after
   deployment host and container and make sure to change
   ``host-ip,host-netmask,host-gateway`` in the script
   (``172.22.0.$COUNT,255.255.252.0,172.22.0.1``) to match your PXE network
   configurations.

.. code::

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

.. note::

   Before you continue, make sure the generated script ``input.csv`` has
   all the information as shown in the example above. If you run into missing
   information, you may need to paste the above command in a bash script and
   execute it.

Assigning a cobbler profile
~~~~~~~~~~~~~~~~~~~~~~~~~~~

The last column in the CSV file specifies which cobbler profile to map
the cobbler system to. You have the following options:

* ubuntu-14.04.3-server-unattended-osic-generic
* ubuntu-14.04.3-server-unattended-osic-generic-ssd
* ubuntu-14.04.3-server-unattended-osic-cinder
* ubuntu-14.04.3-server-unattended-osic-cinder-ssd
* ubuntu-14.04.3-server-unattended-osic-swift
* ubuntu-14.04.3-server-unattended-osic-swift-ssd

Typically, you will use the
``ubuntu-14.04.3-server-unattended-osic-generic`` cobbler profile. It
creatse one RAID10 raid group. The operating system will see this as
``/dev/sda``.

The ``ubuntu-14.04.3-server-unattended-osic-cinder`` cobbler profile
creates one RAID1 raid group and a second RAID10 raid group. These
will be seen by the operating system as ``/dev/sda`` and ``/dev/sdb``,
respectively.

The ``ubuntu-14.04.3-server-unattended-osic-swift`` cobbler profile
creates one RAID1 raid group and 10 RAID0 raid groups each containing one
disk. The HP Storage Controller does not present a disk to the operating
system unless it is in a RAID group. Because swift needs to deal with
individual, non-RAIDed disks, the only way to do this is to put each
disk in its own RAID0 raid group.

You will only use the ``ssd`` cobbler profiles if the servers contain
SSD drives.

Generate cobbler systems
~~~~~~~~~~~~~~~~~~~~~~~~

#. Run the ``generate_cobbler_systems.py`` script to generate a
   cobbler system command for each server and pipe
   the output to bash to add the cobbler system to cobbler:

   .. code::

      $ cd /root/rpc-prep-scripts

        python generate_cobbler_system.py /root/input.csv | bash

#. Verify the cobbler system entries were added by running
   ``cobbler system list``.

#. Run ``cobbler sync``.

Begin PXE booting
~~~~~~~~~~~~~~~~~

Run the following steps to begin PXE booting.

#. Reboot all of the servers with the following command:
   
   .. note::
   
      If the deployment host is the first controller, remove it from
      ``ilo.csv`` to ensure you do not reboot the host running the LXC
      container.

   .. code:: 

      for i in $(cat /root/ilo.csv)
      do
      NAME=$(echo $i | cut -d',' -f1)
      IP=$(echo $i | cut -d',' -f2)
      echo $NAME
      ipmitool -I lanplus -H $IP -U root -P calvincalvin power reset
      done

   .. note::
    
      If the servers are already shut down, change ``power reset`` 
      with ``power on`` in the above command.

#. As the servers finish PXE booting, a call will be made to the cobbler
   API to ensure the server does not PXE boot again.

#. To see which servers are still set to PXE boot, run the
   following command:

   .. code::

      for i in $(cobbler system list)
      do
      NETBOOT=$(cobbler system report --name $i | awk '/^Netboot/ {print $NF}')
      if [[ ${NETBOOT} == True ]]; then
      echo -e "$i: netboot_enabled : ${NETBOOT}"
      fi
      done

   If your server returns ``True``, it has not yet PXE booted.

   .. note::
     
      In case you want to re-pxeboot servers, make sure to clean old
      settings from cobbler with the following command:
      
      .. code::

         for i in `cobbler system list`; do cobbler system remove --name $i; done;


Bootstrapping the servers
~~~~~~~~~~~~~~~~~~~~~~~~~

When all servers finish PXE booting, you will now need to bootstrap the
servers.

#. Run the ``generate_ansible_hosts.py`` python script:

   .. code::
   
      $ cd /root/rpc-prep-scripts

        python generate_ansible_hosts.py /root/input.csv > /root/osic-prep-ansible/hosts

    If this is not an OpenStack-Ansible installation, see
    the following section.

   If this is an OpenStack-Ansible installation, organize the Ansible
   hosts file into groups for controller, logging, compute,
   cinder, and swift.

   An example for OpenStack-Ansible installation:

   .. code::

     [controller]
     744800-infra01.example.com ansible_ssh_host=10.240.0.51
     744819-infra02.example.com ansible_ssh_host=10.240.0.52
     744820-infra03.example.com ansible_ssh_host=10.240.0.53

     [logging]
     744821-logging01.example.com ansible_ssh_host=10.240.0.54

     [compute]
     744822-compute01.example.com ansible_ssh_host=10.240.0.55
     744823-compute02.example.com ansible_ssh_host=10.240.0.56

     [cinder]
     744824-cinder01.example.com ansible_ssh_host=10.240.0.57

     [swift]
     744825-object01.example.com ansible_ssh_host=10.240.0.58
     744826-object02.example.com ansible_ssh_host=10.240.0.59
     744827-object03.example.com ansible_ssh_host=10.240.0.60

The LXC container does not have all of the new server's SSH fingerprints
in its ``known_hosts`` file. You have to programatically add them.

#. Run the following command to add them:

   .. code:: 

      for i in $(cat /root/osic-prep-ansible/hosts | awk /ansible_ssh_host/ | cut -d'=' -f2)
      do
      ssh-keygen -R $i
      ssh-keyscan -H $i >> /root/.ssh/known_hosts
      done

#. Verify Ansible can talk to every server (the password is ``cobbler``):

   .. code::

      $ cd /root/osic-prep-ansible

        ansible -i hosts all -m shell -a "uptime" --ask-pass

#. Generate an SSH key pair for the LXC container:

   .. code::

      $ ssh-keygen

#. Copy the LXC container's SSH public key to the ``osic-prep-ansible``
   directory:

   .. code::
  
      $ cp /root/.ssh/id_rsa.pub /root/osic-prep-ansible/playbooks/files/public_keys/osic-prep


#. Finally, run the ``bootstrap.yml`` Ansible Playbook:

   .. code::

      $ cd /root/osic-prep-ansible

        ansible-playbook -i hosts playbooks/bootstrap.yml --ask-pass

Clean up LVM logical volumes
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If this will be an OpenStack-Ansible installation, you will need to
clean up particular LVM Logical Volumes.

Each server is provisioned with a standard set of LVM Logical Volumes.
Not all servers need all of the LVM Logical Volumes. Clean them up with
the following steps.

#. Remove LVM Logical Volume ``nova00`` from the controller, logging,
   cinder, and swift nodes:

   .. code::

      $ ansible-playbook -i hosts playbooks/remove-lvs-nova00.yml

#. Remove LVM Logical Volume ``deleteme00`` from all nodes:

   .. code::

      $ ansible-playbook -i hosts playbooks/remove-lvs-deleteme00.yml

Update Linux kernel
~~~~~~~~~~~~~~~~~~~

Every server in the OSIC Rackspace cluster is running two Intel X710 10 GbE
NICs. These NICs have not been well tested in Ubuntu. As a result the
upstream i40e driver in the default 14.04.3 Linux kernel will begin
showing issues when you setup VLAN tagged interfaces and bridges.

In order to get around this, install an updated Linux kernel.

Run the following commands:

.. code::

   $ cd /root/osic-prep-ansible

    ansible -i hosts all -m shell -a "apt-get update; apt-get install -y linux-generic-lts-xenial" --forks 25

Reboot nodes
~~~~~~~~~~~~

Finally, reboot all servers:

.. code::

   ansible -i hosts all -m shell -a "reboot" --forks 25

Once all servers reboot, begin installing OpenStack-Ansible.
