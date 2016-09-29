=======================
OSIC deployment process
=======================

Overview
~~~~~~~~

The scenario for the following document assumes you have a number
of bare metal servers and want to build your own cloud on top of them.

The following document provisions your bare metal servers with your
chosen operating system (OS). We recommend a Linux OS if you later
want to use an Open Source platform to build your cloud.

In a production deployment, the process of deploying all
your servers starts by manual provisioning the first of your
servers. The host will become your deployment host and will be
used later to provision the rest of your servers
by booting them over the network. This is called
`PXE Booting <https://en.wikipedia.org/wiki/Preboot_Execution_Environment>`_.

Provisioning the deployment host
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Integrated Lights-Out (iLO) is a card integrated to the motherboard in
most HP ProLiant servers. This allows users to remotely configure,
monitor, and connect to servers without an installed operating system (OS).
This is called out-of-band management. iLO has its own
network interface and is commonly used for:

* Power control of the server
* Mount physical CD/DVD drive or image remotely
* Request an Integrated Remote Console for the server
* Monitor server health

   
Manually provision the deployment host
--------------------------------------

.. important::

   Before you begin this deployment, if you are running an OS that is not Windows,
   you will need to ensure you have the latest Java installed. You can install Java
   for your specific OS from the Java `website <https://java.com/en/download/manual.jsp>`_.

   Verify your Java installation before you begin the following steps.

#. Download the `modified Ubuntu Server 14.04.3 ISO <http://23.253.105.87/ubuntu-14.04.3-server-i40e-hp-raid-x86_64.iso>`_
   to your local machine.

   .. note::

      You must download the modified Ubuntu Server ISO as it contains i40e driver
      version 1.3.47 and HP iLO tools.

#. Boot the deployment host to this ISO using a USB drive, CD/DVD-ROM,
   or iLO.
   The following steps detail how to boot the deployment host
   with the iLO:
   
   #. Open a web browser and browse to the host's iLO IP address.
   
   #. Login with the iLO credentials from your novice install email. 
   
   #. If you are using Safari for Mac and the Java console,
      you will need to allow your java plugin to run in ``unsafe mode``. This is so
      that it can access the ubuntu image from your local directory.
      
      #. Look for iLO IP on Safari browser.
      #. Navigate to the ``Safari`` tab, ``Preferences``, ``Security``,
         and then ``Plugin-settings``.
      #. Select ``Java`` from left panel.
      #. Select the relevant iLO IP from right panel. The default is selected to `Allow`,
         change it by selecting `Run in unsafe mode`.
      #. Save and close.
                                                                        
   #. Select ``Remote Console`` from the left panel in the GUI.
   
   #. Launch a remote console from selection available.
      Windows users will request a .NET console, all other OSes
      will need to request a Java console.
      
   #. After the console launches, select ``Virtual Drives`` from the iLO
      console.
      
      .. note::
         
         Depending on your personal network connection, speed times when running
         the console can vary.

   #. Press ``Image File CD/DVD-ROM``, then select the Ubuntu image you
      downloaded to your local directory.

   #. Click ``Power Switch`` and select ``Reset`` to reboot the
      host from the image.

   #. Unselect ``Image File CD/DVD-ROM`` from the ``Virtual Drives`` tab.
      This ensures future server reboots do not continue to use it to boot.

Once the deployment host is booted to the ISO, follow these steps to
begin installation:

#. Select the `Language` you want to boot in, press `Enter`.

#. Hit `Fn` and `F6`.
   
   .. note::
      
      Depending on your keyboard configuration, ensure that you have
      the `Fn` keys enabled as standard function keys.

#. Dismiss the ``Expert mode`` menu by hitting the `Esc` key.

#. Scroll to the beginning of the line and delete: ``file=/cdrom/preseed/ubuntu-server.seed``.
   Insert ``preseed/url=http://23.253.105.87/osic.seed`` in its place.

#. Hit `Enter` to begin the install process. The console may appear to
   freeze for sometime.

The console will reboot, and you will go through the following menu
prompts:

#. Select the `Language` you want to boot in, press `Enter`.

#. Select your `Location`.

#. Configure your `Keyboard` preferences.

#. Configure your `Network` preferences.

   When configuring your preferences, the DHCP detection will fail.
   You will need to manually select the proper network interface, ``p1p1``. 
   Manually configure a free IP from the **PXE** network. You will need to 
   refer to your novice install email to find the **PXE** network information.

   #. At the prompt for name servers, insert: `8.8.8.8 8.8.4.4`.

   #. If you receive an error stating: "``/dev/sda`` contains GPT signatures",
      it indicates that it had a GPT table. If you encounter this error
      select, ``No`` and continue.

#. Once networking is configured, the preseed file will be downloaded.

The Ubuntu install will be finished when the system reboots and a login
prompt appears.

Update Linux kernel
-------------------

#. Once the system boots, open a terminal in your computer and SSH into it to using the
   IP address you manually assigned.
   
   .. note::
      
      From this point you do not need the iLO remote console.

#. Login with username ``root`` and password ``cobbler``.

#. Update the Linux kernel on the deployment host to get an updated upstream
   i40e driver.

   .. code:: console

      apt-get update
      apt-get install -y linux-generic-lts-xenial

#. After the update finishes, ``reboot`` the server.


Download and setup the osic-prep LXC container
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

There are numerous tools that can help you PXE boot your servers. We
recommend the use of `Cobbler <http://cobbler.github.io/>`_ as it is powerful,
easy to use, and is quick to set up network installation environments.
Cobbler is a Linux based provisioning system which configures network installations
from MAC addresses, manages DNS, and serves DHCP requests.

The following steps take you through the download of a pre-packaged LXC container
that contains Cobbler. Cobbler is the main tool you use to PXE boot the rest of
your servers.

SSH to your deployment host once it has been provisioned.

Setup LXC Linux bridge
----------------------

#. Install the necessary packages:

   .. code:: console

      apt-get install vlan bridge-utils

#. Reconfigure the network interface file ``/etc/network/interfaces`` to
   match the following. Your IP addresses and ports will differ.

   .. code:: ini

      # The loopback network interface
      auto lo
      iface lo inet loopback

      auto p1p1
      iface p1p1 inet manual

      # Container Bridge
      auto br-pxe
      iface br-pxe inet static
      address 172.22.0.21
      netmask 255.255.252.0
      gateway 172.22.0.1
      dns-nameservers 8.8.8.8 8.8.4.4
      bridge_ports p1p1
      bridge_stp off
      bridge_waitport 0
      bridge_fd 0

#. Bring up the ``br-pxe`` interface. We recommend you have access to the iLO in case the
   following commands fail and you lose network connectivity:

   .. code:: console

      ifdown p1p1; ifup br-pxe

Install LXC and configure LXC container
---------------------------------------

#. Install LXC:

   .. code:: console

      apt-get install lxc

#. Change into the root home directory:

   .. code:: console

      cd /root

#. Download the LXC container to the deployment host:

   .. code:: console

      wget http://23.253.105.87/osic.tar.gz
   

#. Untar the LXC container:

   .. code:: console

      tar xvzf /root/osic.tar.gz

#. Move the LXC container directory into the right directory:

   .. code:: console

      mv /root/osic-prep /var/lib/lxc/

#. Stop the LXC container. Verify by running:
   
   .. code:: console
      
      lxc-ls -f
      
#. Open ``/var/lib/lxc/osic-prep/config`` and change ``lxc.network.ipv4 =
   172.22.0.22/22`` to a free IP address from the PXE network you are
   using.
   
   .. note::

      Do not forget to set the CIDR notation as well. If your PXE
      network already is **172.22.0.22/22**, you do not need to make further
      changes.

   .. code:: ini

      lxc.network.type = veth
      lxc.network.name = eth1
      lxc.network.ipv4 = 172.22.0.22/22
      lxc.network.link = br-pxe
      lxc.network.hwaddr = 00:16:3e:xx:xx:xx
      lxc.network.flags = up
      lxc.network.mtu = 1500

#. Start the LXC container:

   .. code:: console

      lxc-start -d --name osic-prep

You can now ping the IP address you just set for the LXC container from
the host.

Configure LXC container
-----------------------

There are a few configuration changes that need to be made to the
pre-packaged LXC container for it to function on your network.

#. Attach the LXC container:

   .. code:: console

      lxc-attach --name osic-prep

#. If you changed the IP address above, reconfigure the DHCP server
   by running the following sed commands. You will need to change
   ``172.22.0.22`` to match the IP address you set above:

   .. code:: console

      sed -i '/^next_server: / s/ .*/ 172.22.0.22/' /etc/cobbler/settings

      sed -i '/^server: / s/ .*/ 172.22.0.22/' /etc/cobbler/settings

#. Open ``/etc/cobbler/dhcp.template`` and reconfigure your DHCP settings.
   Change the `subnet`, `netmask`, `option routers`, `option subnet-mask`,
   and `range dynamic-bootp` parameters to match your network:

   .. code:: ini

      subnet 172.22.0.0 netmask 255.255.252.0 {
           option routers             172.22.0.1;
           option domain-name-servers 8.8.8.8;
           option subnet-mask         255.255.252.0;
           range dynamic-bootp        172.22.0.23 172.22.0.200;
           default-lease-time         21600;
           max-lease-time             43200;
           next-server                $next_server;

#. Restart Cobbler and sync it:

   .. code:: console

      service cobbler restart

      cobbler sync

You can now manually PXE boot any servers.

PXE boot the servers
~~~~~~~~~~~~~~~~~~~~

In order to PXE boot your servers, you need to obtain the MAC address of the
network interface (For example, **p1p1**) that is configured to PXE boot on every
server. The MAC addresses must be mapped to their respective hostname.

#. Before you begin PXE booting your servers, we recommend running the following
   command to list all processes to ensure DHCP is running:
  
    .. code:: console
      
       ps axww

#. Go to root home directory:

   .. code:: console

      cd /root

#. Log into the LXC container and create a CSV file named ``ilo.csv``.

   .. note::
      
      Each line should have a hostname to assign for the server, its iLO IP
      address, type of node it will be (controller, logging, compute, cinder,
      swift). Ensure hostnames are meaningful to you, For example, `controller01`,
      and `controller02`.

#. Use the information from your novice install email to create the CSV.
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
----------------

The following script creates a CSV named ``input.csv`` in this format:

   .. code:: ini

      hostname,mac-address,host-ip,host-netmask,host-gateway,dns,pxe-interface,cobbler-profile

If you will be deploying OpenStack, we recommend
ordering the CSV file as controller, logging, compute, cinder, and
swift. For example:

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

The script loops through each iLO IP address in ``ilo.csv`` to
obtain the MAC address of the network interface configured to PXE boot and
setup rest of information as well as shown above.

#. Make sure you have installed ssh-pass before you run the following script.
   If you do not have ssh-pass installed, run:
   
   .. code:: console
      
      install ssh-pass

#. Run the following script in your local console: 

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
           MAC=`sshpass -p password ssh -o StrictHostKeyChecking=no root@$IP show /system1/network1/Integrated_NICs | grep Port1 | cut -d'=' -f2`
           #hostname,mac-address,host-ip,host-netmask,host-gateway,dns,pxe-interface,cobbler-profile
           echo "$NAME,${MAC//[$'\t\r\n ']},172.22.0.$COUNT,255.255.252.0,172.22.0.1,8.8.8.8,p1p1,$SEED" | tee -a input.csv

           (( COUNT++ ))
       done

#. Make sure the generated script ``input.csv`` has all the information as
   shown in the above example. If you run into some missing information, you
   may need to paste the above command in a bash script and execute it.

Assigning a Cobbler profile
---------------------------

The last column in the CSV file specifies which Cobbler profile to map
the Cobbler system to. You have the following options:

* `ubuntu-14.04.3-server-unattended-osic-generic`

  Typically, you will use the `ubuntu-14.04.3-server-unattended-osic-generic`
  Cobbler profile. It creates one RAID10 raid group. The operating system will
  see this as ``/dev/sda``.
  
* `ubuntu-14.04.3-server-unattended-osic-generic-ssd`
* `ubuntu-14.04.3-server-unattended-osic-cinder`

  The `ubuntu-14.04.3-server-unattended-osic-cinder` Cobbler profile
  creates one RAID1 raid group and a second RAID10 raid group. These
  will be seen by the operating system as ``/dev/sda`` and ``/dev/sdb``,
  respectively.
  
* `ubuntu-14.04.3-server-unattended-osic-cinder-ssd`
* `ubuntu-14.04.3-server-unattended-osic-swift`
  
  The `ubuntu-14.04.3-server-unattended-osic-swift` Cobbler profile
  creates one RAID1 raid group and 10 RAID0 raid groups each containing one
  disk. The HP storage controller does not present a disk to the operating
  system unless it is in a RAID group. Because swift needs to deal with
  individual, non-RAIDed disks, the only way to do this is to put each
  disk in its own RAID0 raid group.
  
* `ubuntu-14.04.3-server-unattended-osic-swift-ssd`

.. important::

   You will only use the `ssd` Cobbler profiles if the servers contain SSD drives.

Generate Cobbler systems
------------------------

The ``generate_cobbler_systems.py`` script generates a list of
`cobbler system` commands to the standard output.

#. Pipe the standard output to ``bash``. The servers will be
   added to Cobbler (internally done by issuing a cobbler system command):

   .. code:: console

      cd /root/rpc-prep-scripts

      python generate_cobbler_system.py /root/input.csv | bash

#. Verify the `cobbler system` entries were added. Run:

   .. code:: console

      cobbler system list

#. Once all of the `cobbler systems` are setup, run the following command:

   .. code:: console

      cobbler sync

Begin PXE booting
-----------------

#. Set the servers to boot from PXE on the next reboot. Reboot all of the
   servers with the following command (if the deployment host is in ``ilo.csv``,
   you will want to remove it from the file so you do not
   reboot the host running the LXC container).
   Make sure you change ``USERNAME`` and ``PASSWORD``
   to your server's iLO credentials before running the command:

   .. code:: ini

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

   .. code:: ini

      for i in $(cobbler system list)
      do
      NETBOOT=$(cobbler system report --name $i | awk '/^Netboot/ {print $NF}')
      if [[ ${NETBOOT} == True ]]; then
      echo -e "$i: netboot_enabled : ${NETBOOT}"
      fi
      done

   Any server that returns ``True`` has not yet PXE booted. Rerun last
   command until there is no output to make sure all your servers has
   finished pxebooting.
   
   Time to wait depends on the number of servers you are deploying. If
   somehow, one or two servers did not go through for a
   long time, you may want to investigate them with their iLO console. In
   most cases, this is due to rebooting those servers either fails or
   hangs, so you may need to reboot them manually with iLO.

   .. note::

      To re-pxeboot servers, make sure to clean old
      settings from cobbler with the following command:

      .. code:: ini

         for i in `cobbler system list`; do cobbler system remove --name $i; done;
         

Bootstrapping the servers
~~~~~~~~~~~~~~~~~~~~~~~~~

When all servers finish PXE booting, bootstrap the servers.

Generate Ansible inventory
--------------------------

#. Run the ``generate_ansible_hosts.py`` Python script:

   .. code:: console

      cd /root/rpc-prep-scripts

      python generate_ansible_hosts.py /root/input.csv > /root/osic-prep-ansible/hosts

#. (Optional) If this will be an OpenStack installation, organize the
   hosts file into groups for controller, logging, compute, cinder, and
   swift. For example:

   .. code:: ini

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

Verify connectivity
-------------------

The LXC container does not have all of the new server's SSH fingerprints
in the ``known_hosts`` file. This is needed to bypass prompts and
create a silent login when SSHing to servers.

#. Add the SSH fingerprints to ``known_hosts`` by running the following
   bash script:

   .. code:: ini

      for i in $(cat /root/osic-prep-ansible/hosts | awk /ansible_ssh_host/ | cut -d'=' -f2)
      do
      ssh-keygen -R $i
      ssh-keyscan -H $i >> /root/.ssh/known_hosts
      done

#. Verify Ansible can talk to every server. Your password is `cobbler`:

   .. code:: console

      cd /root/osic-prep-ansible

      ansible -i hosts all -m shell -a "uptime" --ask-pass

Setup SSH public keys
---------------------

#. Generate an SSH key pair for the LXC container:

   .. code:: console

      ssh-keygen

#. Copy the LXC container's SSH public key to the ``osic-prep-ansible``
   directory:

   .. code:: console

      cp /root/.ssh/id_rsa.pub /root/osic-prep-ansible/playbooks/files/public_keys/osic-prep

Bootstrap the servers
---------------------

#. Run the ``bootstrap.yml`` Ansible Playbook. Your password is `cobbler`:

   .. code:: console

      cd /root/osic-prep-ansible

      ansible-playbook -i hosts playbooks/bootstrap.yml --ask-pass

Clean up LVM logical volumes
----------------------------

Each server is provisioned with a standard set of LVM Logical Volumes and
not all servers need all of the LVM Logical Volumes. Clean them up with
the following steps.

#. Remove LVM logical volume ``nova00`` from the controller, logging,
   cinder, and swift nodes:

   .. code:: console

      ansible-playbook -i hosts playbooks/remove-lvs-nova00.yml

#. Remove LVM Logical Volume ``deleteme00`` from all nodes:

   .. code:: console

      ansible-playbook -i hosts playbooks/remove-lvs-deleteme00.yml

Update Linux kernel
-------------------

Every server in the OSIC RAX cluster is running two Intel X710 10 GbE
NICs.

.. important::
   
   These NICs have not been well tested in Ubuntu and as such the
   upstream i40e driver in the default 14.04.3 Linux kernel will begin
   showing issues when you setup VLAN tagged interfaces and bridges.

To get around this, install an updated Linux kernel by running the
following commands:

.. code:: console

   cd /root/osic-prep-ansible

   ansible -i hosts all -m shell -a "apt-get update; apt-get install -y linux-generic-lts-xenial" --forks 25

Reboot nodes
------------

Reboot all servers:

.. code:: console

   ansible -i hosts all -m shell -a "reboot" --forks 25

Once all servers reboot, you can begin installing OpenStack.

Appendix
~~~~~~~~

Novice install email
----------------------

#. Login details

   .. code-block::

      OSIC VPN
         Username: osic

         VPN pass: *********
      iLO
         Username: root

         Password: *********

#. User details

   #. To access the OSIC servers, you must be connected to the OSIC VPN. 

      .. note::

         We recommend using Firefox, or Safari for Mac.

   #. Disconnect from any VPN (corporate) you are connected to.
   #. Install an F5's SSL VPN.

      .. note::

         The SSL VPN is a browser plugin as the Chrome web browser does
         not support automatic plugin installation.

   #. Open ``https://72.3.183.39`` in your browser and follow the instructions.
   #. The VPN endpoint uses a self-signed SSL certificate, so you may need to
      bypass a security warning in your browser, however the traffic is encrypted.
   #. You are connected to the OSIC VPN as long as you have the browser up and
      logged in to the URL.

#. Servers

   The following 12 servers have been allocated to you. The server
   hostnames (as we identify them in our internal systems) are below as
   well as the iLO IP address for each server. Use the iLO IP addresses, and
   not the hostnames, to access the servers via iLO.

   .. code:: ini

      [M8-11]
      729429-comp-disk-067.cloud2.osic.rackspace.com 10.15.243.160
      729428-comp-disk-068.cloud2.osic.rackspace.com 10.15.243.159
      729427-comp-disk-069.cloud2.osic.rackspace.com 10.15.243.158
      729426-comp-disk-070.cloud2.osic.rackspace.com 10.15.243.157
      729425-comp-disk-071.cloud2.osic.rackspace.com 10.15.243.156
      729424-comp-disk-072.cloud2.osic.rackspace.com 10.15.243.155
      729423-comp-disk-073.cloud2.osic.rackspace.com 10.15.243.154
      729422-comp-disk-074.cloud2.osic.rackspace.com 10.15.243.153
      729421-comp-disk-075.cloud2.osic.rackspace.com 10.15.243.152
      729420-comp-disk-076.cloud2.osic.rackspace.com 10.15.243.151
      729419-comp-disk-077.cloud2.osic.rackspace.com 10.15.243.150
      729418-comp-disk-078.cloud2.osic.rackspace.com 10.15.243.149
      729417-comp-disk-079.cloud2.osic.rackspace.com 10.15.243.148
      729416-comp-disk-080.cloud2.osic.rackspace.com 10.15.243.147
      729415-comp-disk-081.cloud2.osic.rackspace.com 10.15.243.146
      729414-comp-disk-082.cloud2.osic.rackspace.com 10.15.243.145
      729413-comp-disk-083.cloud2.osic.rackspace.com 10.15.243.144
      729412-comp-disk-084.cloud2.osic.rackspace.com 10.15.243.143
      729411-comp-disk-085.cloud2.osic.rackspace.com 10.15.243.142
      729410-comp-disk-086.cloud2.osic.rackspace.com 10.15.243.141
      729409-comp-disk-087.cloud2.osic.rackspace.com 10.15.243.140
      729408-comp-disk-088.cloud2.osic.rackspace.com 10.15.243.139


   Each server has the following specifications:

    * :Model: HP DL380 Gen9
    * :Processor: 2x 12-core Intel E5-2680 v3 @ 2.50GHz
    * :RAM: 256GB RAM
    * :Disk: 12x 600GB 15K SAS - RAID10
    * :NICS: 2x Intel X710 Dual Port 10 GbE

   All servers contain two Intel X710 10 GbE NICs.

#. Server cabling and switch port configuration

   Use available subnets on your need while excluding specified reserved IP
   addresses for each subnet. The switchport networking has been configured
   in a way that allows you to PXE boot from ``p1p1`` or ``p4p1``. 
   Pick one of those network interfaces to PXE boot from for every server.

   ** Subnets**
   
   .. note:: 
   
      The first 20 IP’s on each subnet are reserved, please start on `.21`.

   ======   ============================= ===============
    VLAN     SUBNET                        GATEWAY       
   ======   ============================= ===============
    810     172.22.4.0/22 - PXE            172.22.4.1    
    812     172.22.12.0/22 - MANAGEMENT    172.22.12.1   
    840     172.22.140.0/22 - STORAGE      172.22.140.1  
    841     172.22.144.0/22 - OVERLAY      172.22.144.1  
    842     172.22.148.0/22 - FLAT         172.22.148.1 
   ======   ============================= ===============

#. Troubleshooting iLO connectivity

   If you lose connectivity to the server(s) iLO, try to reset it using
   the following ipmitool command:

   .. code:: console

      ipmitool -I lanplus -U root -p password -H <iLO IP> mc reset warm

   If you still have connectivity problems, submit open a ticket with the
   `OSIC <https://github.com/osic/osic-clouds/issues>`_ team
   identifying the problematic servers.
