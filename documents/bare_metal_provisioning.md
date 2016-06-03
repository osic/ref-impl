OSIC Deployment Process
=======================

Table of Contents
-----------------

* [Provisioning the Deployment Host](https://gist.github.com/jameswthorne/6b2498baf438392feeda#provisioning-the-deployment-host)
* [Download and Setup the osic-prep LXC Container](https://gist.github.com/jameswthorne/6b2498baf438392feeda#download-and-setup-the-osic-prep-lxc-container)
* [PXE Boot the Servers](https://gist.github.com/jameswthorne/6b2498baf438392feeda#pxe-boot-the-servers)
* [Bootstrapping the Servers](https://gist.github.com/jameswthorne/6b2498baf438392feeda#bootstrapping-the-servers)
* [Create the osic-prep LXC Container](https://gist.github.com/jameswthorne/6b2498baf438392feeda#create-the-osic-prep-lxc-container)

Provisioning the Deployment Host
--------------------------------

You have been allocated a certain number of bare metal servers. There is currently nothing running on these servers. You will need to manually provision the first host. This will become your deployment host that will be used to provision the rest of the servers using PXE.

### Manually Provision the Deployment Host

First, download a [modified Ubuntu Server 14.04.3 ISO](http://public.thornelabs.net/ubuntu-14.04.3-server-i40e-hp-raid-x86_64.iso). The modified Ubuntu Server ISO contains i40e driver version 1.3.47 and HP iLO tools.

Boot the deployment host to this ISO using a USB drive, CD/DVD-ROM, iDRAC, or iLO. Whatever is easiest.

Once the deployment host is booted to the ISO, follow these steps to begin installation:

1. Select __Language__

2. Hit __Fn + F6__

3. Dismiss the __Expert mode__ menu by hiting __Esc__.

4. Scroll to the beginning of the line and delete __file=/cdrom/preseed/ubuntu-server.seed__.

5. Type __preseed/url=http://public.thornelabs.net/ubuntu-server-14.04-unattended-iso-osic-generic.seed__

6. Hit __Enter__ to begin the install process.

7. You will be prompted for the following menus:

   * Select a language
   * Select your location
   * Configure the keyboard
   * Configure the network

  DHCP detection will fail. You will need to manually select the proper network interface - typically __p1p1__ - and manually configure networking on the __PXE__ network (refer to your onboarding email to find the __PXE__ network information).

Once networking is configured, the Preseed file will be downloaded. The remainder of the Ubuntu install will be unattended.

The Ubuntu install will be finished when the system reboots and a login prompt appears.

### Update Linux Kernel

Once the system boots, it can be SSH'd to using the IP address you manually assigned. Login with username __root__ and password __cobbler__.

You will need to update the Linux kernel on the deployment host in order to get an updated upstream i40e driver.

    apt-get update; apt-get install -y linux-generic-lts-xenial

When the update finishes running, reboot the server and proceed with the rest of the guide.

Download and Setup the osic-prep LXC Container
----------------------------------------------

With the deployment host provisioning done, SSH to it.

Next, you will download a pre-packaged LXC container that contains everything you need to PXE boot the rest of the servers.

### Setup LXC Linux Bridge

In order to use the LXC container, a new bridge will need to be created: __br-pxe__.

First, install the necessary packages:

    apt-get install vlan bridge-utils

Reconfigure the network interface file to match the following (your IP addresses and ports will most likely be different):

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

Bring up __br-pxe__. I recommend you have access to the iLO in case the following commands fail and you lose network connectivity:

    ifdown p1p1; ifup br-pxe

### Install LXC and Configure LXC Container

Install the necessary LXC package:

    apt-get install lxc

Change into root's home directory:

    cd /root

Download the LXC container to the deployment host:

    wget http://public.thornelabs.net/osic-prep-lxc-container.tar.gz
    
Untar the LXC container:

    tar xvzf /root/osic-prep-lxc-container.tar.gz
    
Move the LXC container directory into the proper directory:

    mv /root/osic-prep /var/lib/lxc/

Once moved, the LXC container should be stopped, verify by running `lxc-ls -f`. Before starting it, open __/var/lib/lxc/osic-prep/config__ and change __lxc.network.ipv4 = 172.22.0.22/22__ to the PXE network you are using. Do not forget to set the CIDR notation as well. If your PXE network already is __172.22.0.22/22__, you do not need to make further changes.

    lxc.network.type = veth
    lxc.network.name = eth1
    lxc.network.ipv4 = 172.22.0.22/22
    lxc.network.link = br-pxe
    lxc.network.hwaddr = 00:16:3e:xx:xx:xx
    lxc.network.flags = up
    lxc.network.mtu = 1500

Start the LXC container:

    lxc-start -d --name osic-prep

You should be able to ping the IP address you just set for the LXC container from the host.

### Configure LXC Container

There are a few configuration changes that need to be made to the pre-packaged LXC container for it to function on your network.

Start by attaching to the LXC container:

    lxc-attach --name osic-prep

If you had to change the IP address above, reconfigure the DHCP server by running the following sed commands. You will need to change __172.22.0.22__ to match the IP address you set above:

    sed -i '/^next_server: / s/ .*/ 172.22.0.22/' /etc/cobbler/settings

    sed -i '/^server: / s/ .*/ 172.22.0.22/' /etc/cobbler/settings

Open __/etc/cobbler/dhcp.template__ and reconfigure your DHCP settings. You will need to change the __subnet__, __netmask__, __option routers__, __option subnet-mask__, and __range dynamic-bootp__ parameters to match your network.

    subnet 172.22.0.0 netmask 255.255.252.0 {
         option routers             172.22.0.1;
         option domain-name-servers 8.8.8.8;
         option subnet-mask         255.255.252.0;
         range dynamic-bootp        172.22.0.23 172.22.0.200;
         default-lease-time         21600;
         max-lease-time             43200;
         next-server                $next_server;

Pull updates for __osic-prep-ansible__:

    cd /root/osic-prep-ansible

    git pull origin master

This is optional, create the roles directory and download the __rpc_networking__ Playbook:

    mkdir -p /root/osic-prep-ansible/playbooks/roles

    cd /root/osic-prep-ansible/playbooks/roles

    git clone https://github.com/jameswthorne/ansible-role-rpc_networking.git rpc_networking

Pull updates for __osic-preseeds__:

    cd /opt/osic-preseeds
    
    git pull origin master

Finally, restart Cobbler and sync it:

    service cobbler restart

    cobbler sync

At this point you can PXE boot any servers, but it is still a manual process. In order for it to be an automated process, a CSV file needs to be created.

PXE Boot the Servers
--------------------

### Gather MAC Addresses

You will need to obtain the MAC address of the network interface (e.g. p1p1) configured to PXE boot on every server. Be sure the MAC addresses are mapped to their respective hostname.

You can do this by logging into the LXC container and creating a CSV file named __ilo.csv__. Use the information from your onboarding email to create the CSV.

For example:

    729427-controller01,10.15.243.158
    729426-controller02,10.15.243.157
    729425-controller03,10.15.243.156
    729424-network01,10.15.243.155
    729423-network02,10.15.243.154
    729422-logging01,10.15.243.153
    729421-compute01,10.15.243.152
    729420-compute02,10.15.243.151
    729419-compute03,10.15.243.150
    729418-compute04,10.15.243.149
    729417-compute05,10.15.243.148
    729416-compute06,10.15.243.147
    729415-compute07,10.15.243.146
    729414-compute08,10.15.243.145
    729413-compute09,10.15.243.144
    729412-cinder01,10.15.243.143
    729411-cinder02,10.15.243.142
    729410-swift01,10.15.243.141
    729409-swift02,10.15.243.140
    729408-swift03,10.15.243.139

I recommend removing the deployment host you manually provisioned from this CSV so you do not accidentally reboot the host you are working from.

Once the CSV file is created, you can loop through each iLO to obtain the MAC address of the network interface configured to PXE boot with the following command:

    for i in $(cat ilo.csv)
    do
    NAME=$(echo $i | cut -d',' -f1)
    IP=$(echo $i | cut -d',' -f2)
    MAC=$(sshpass -p calvincalvin ssh -o StrictHostKeyChecking=no root@$IP show /system1/network1/Integrated_NICs | grep Port1 | cut -d'=' -f 2)
    echo "$NAME,$MAC"
    done

Once this information is collected, it will be used to create another CSV file that will be the input for many different steps in the build process.

### Create Input CSV

Create a CSV named __input.csv__ in the following format. Use whatever text editor foo you have to create the CSV file.

    hostname,mac-address,host-ip,host-netmask,host-gateway,dns,pxe-interface,cobbler-profile

If this will be an openstack-ansible or RPC-O installation, it is recommended to order the rows in the CSV file in the following order, otherwise order the rows however you wish:

1. Controller nodes
2. Logging nodes
3. Compute nodes
4. Cinder nodes
5. Swift nodes

An example for openstack-ansible or RPC-O installations:

    744800-infra01.example.com,A0:36:9F:7F:70:C0,10.240.0.51,255.255.252.0,10.240.0.1,8.8.8.8,p1p1,ubuntu-14.04.3-server-unattended-osic-generic
    744819-infra02.example.com,A0:36:9F:7F:6A:C8,10.240.0.52,255.255.252.0,10.240.0.1,8.8.8.8,p1p1,ubuntu-14.04.3-server-unattended-osic-generic
    744820-infra03.example.com,A0:36:9F:82:8C:E8,10.240.0.53,255.255.252.0,10.240.0.1,8.8.8.8,p1p1,ubuntu-14.04.3-server-unattended-osic-generic
    744821-logging01.example.com,A0:36:9F:82:8C:E9,10.240.0.54,255.255.252.0,10.240.0.1,8.8.8.8,p1p1,ubuntu-14.04.3-server-unattended-osic-generic
    744822-compute01.example.com,A0:36:9F:82:8C:EA,10.240.0.55,255.255.252.0,10.240.0.1,8.8.8.8,p1p1,ubuntu-14.04.3-server-unattended-osic-generic
    744823-compute02.example.com,A0:36:9F:82:8C:EB,10.240.0.56,255.255.252.0,10.240.0.1,8.8.8.8,p1p1,ubuntu-14.04.3-server-unattended-osic-generic
    744824-cinder01.example.com,A0:36:9F:82:8C:EC,10.240.0.57,255.255.252.0,10.240.0.1,8.8.8.8,p1p1,ubuntu-14.04.3-server-unattended-osic-cinder
    744825-object01.example.com,A0:36:9F:7F:70:C1,10.240.0.58,255.255.252.0,10.240.0.1,8.8.8.8,p1p1,ubuntu-14.04.3-server-unattended-osic-swift
    744826-object02.example.com,A0:36:9F:7F:6A:C2,10.240.0.59,255.255.252.0,10.240.0.1,8.8.8.8,p1p1,ubuntu-14.04.3-server-unattended-osic-swift
    744827-object03.example.com,A0:36:9F:82:8C:E3,10.240.0.60,255.255.252.0,10.240.0.1,8.8.8.8,p1p1,ubuntu-14.04.3-server-unattended-osic-swift

### Assigning a Cobbler Profile

The last column in the CSV file specifies which Cobbler Profile to map the Cobbler System to. You have the following options:

* ubuntu-14.04.3-server-unattended-osic-generic
* ubuntu-14.04.3-server-unattended-osic-generic-ssd
* ubuntu-14.04.3-server-unattended-osic-cinder
* ubuntu-14.04.3-server-unattended-osic-cinder-ssd
* ubuntu-14.04.3-server-unattended-osic-swift
* ubuntu-14.04.3-server-unattended-osic-swift-ssd

Typically, you will use the __ubuntu-14.04.3-server-unattended-osic-generic__ Cobbler Profile. It will create one RAID10 raid group. The operating system will see this as __/dev/sda__.

The __ubuntu-14.04.3-server-unattended-osic-cinder__ Cobbler Profile will create one RAID1 raid group and a second RAID10 raid group. These will be seen by the operating system as __/dev/sda__ and __/dev/sdb__, respectively.

The __ubuntu-14.04.3-server-unattended-osic-swift__ Cobbler Profile will create one RAID1 raid group and 10 RAID0 raid groups each containing one disk. The HP Storage Controller will not present a disk to the operating system unless it is in a RAID group. Because Swift needs to deal with individual, non-RAIDed disks, the only way to do this is to put each disk in its own RAID0 raid group.

You will only use the __ssd__ Cobbler Profiles if the servers contain SSD drives.

### Generate Cobbler Systems

With this CSV file in place, run the __generate_cobbler_systems.py__ script to generate a __cobbler system__ command for each server and pipe the output to `bash` to actually add the __cobbler system__ to Cobbler:

    cd /root/rpc-prep-scripts

    python generate_cobbler_system.py /root/input.csv | bash

Verify the __cobbler system__ entries were added by running `cobbler system list`.

Once all of the __cobbler systems__ are setup, run `cobbler sync`.

### Begin PXE Booting

To begin PXE booting, reboot all of the servers with the following command (if the deployment host is the first controller, you will want to __remove__ it from the __ilo.csv__ file so you don't reboot the host running the LXC container):

    for i in $(cat /root/ilo.csv)
    do
    NAME=$(echo $i | cut -d',' -f1)
    IP=$(echo $i | cut -d',' -f2)
    echo $NAME
    ipmitool -I lanplus -H $IP -U root -P calvincalvin power reset
    done

As the servers finish PXE booting, a call will be made to the cobbler API to ensure the server does not PXE boot again.

To quickly see which servers are still set to PXE boot, run the following command:

    for i in $(cobbler system list)
    do
    NETBOOT=$(cobbler system report --name $i | awk '/^Netboot/ {print $NF}')
    if [[ ${NETBOOT} == True ]]; then 
    echo -e "$i: netboot_enabled : ${NETBOOT}"
    fi
    done

Any server which returns __True__ has not yet PXE booted.

Bootstrapping the Servers
-------------------------

With the servers PXE booted, you will now need to bootstrap the servers.

### Generate Ansible Inventory

Start by running the `generate_ansible_hosts.py` Python script:

    cd /root/rpc-prep-scripts

    python generate_ansible_hosts.py /root/input.csv > /root/osic-prep-ansible/hosts

If this will be an openstack-ansible or RPC-O installation, organize the Ansible __hosts__ file into groups for __controller__, __logging__, __compute__, __cinder__, and __swift__, otherwise leave the Ansible __hosts__ file as it is and jump to the next section.

An example for openstack-ansible or RPC-O installations:

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

### Verify Connectivity

The LXC container will not have all of the new server's SSH fingerprints in its __known_hosts__ file. Programatically add them by running the following command:

    for i in $(cat /root/osic-prep-ansible/hosts | awk /ansible_ssh_host/ | cut -d'=' -f2)
    do
    ssh-keygen -R $i
    ssh-keyscan -H $i >> /root/.ssh/known_hosts
    done

Verify Ansible can talk to every server (the password is __cobbler__):

    cd /root/osic-prep-ansible

    ansible -i hosts all -m shell -a "uptime" --ask-pass

### Setup SSH Public Keys

Generate an SSH key pair for the LXC container:

    ssh-keygen

Copy the LXC container's SSH public key to the __osic-prep-ansible__ directory:

    cp /root/.ssh/id_rsa.pub /root/osic-prep-ansible/playbooks/files/public_keys/osic-prep

### Bootstrap the Servers

Finally, run the bootstrap.yml Ansible Playbook:

    cd /root/osic-prep-ansible

    ansible-playbook -i hosts playbooks/bootstrap.yml --ask-pass

### Clean Up LVM Logical Volumes

If this will be an openstack-ansible or RPC-O installation, you will need to clean up particular LVM Logical Volumes.

Each server is provisioned with a standard set of LVM Logical Volumes. Not all servers need all of the LVM Logical Volumes. Clean them up with the following steps.

Remove LVM Logical Volume __nova00__ from the Controller, Logging, Cinder, and Swift nodes:

    ansible-playbook -i hosts playbooks/remove-lvs-nova00.yml

Remove LVM Logical Volume __deleteme00__ from all nodes:

    ansible-playbook -i hosts playbooks/remove-lvs-deleteme00.yml

### Update Linux Kernel

Every server in the OSIC RAX Cluster is running two Intel X710 10 GbE NICs. These NICs have not been well tested in Ubuntu and as such the upstream i40e driver in the default 14.04.3 Linux kernel will begin showing issues when you setup VLAN tagged interfaces and bridges.

In order to get around this, you must install an updated Linux kernel.

You can quickly do this by running the following commands:

    cd /root/osic-prep-ansible

    ansible -i hosts all -m shell -a "apt-get update; apt-get install -y linux-generic-lts-xenial" --forks 25

### Reboot Nodes

Finally, reboot all servers:

    ansible -i hosts all -m shell -a "reboot" --forks 25

Once all servers reboot, you can begin installing openstack-ansible or RPC-O.

Create the osic-prep LXC Container
----------------------------------

_The following steps only need to be done if the LXC container needs to be rebuilt._

### Setup the Build Host

Login to a build host. This could be any Ubuntu system.

In order to use the LXC container, a new bridge will need to be created: __br-pxe__.

First, install the necessary networking packages:

    apt-get install vlan bridge-utils

Reconfigure the network interface file to match the following:

    # The loopback network interface
    auto lo
    iface lo inet loopback

    auto
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

Bring up __br-pxe__:

    ifdown p1p1; ifup br-pxe

Install necessary LXC packages:

    apt-get install lxc

Create the LXC container:

    lxc-create -t download -n osic-prep -- --dist ubuntu --release trusty --arch amd64

Append the following to __/var/lib/lxc/osic-prep/config__:

    lxc.network.type = veth
    lxc.network.name = eth1
    lxc.network.ipv4 = 172.22.0.22/22
    lxc.network.link = br-pxe
    lxc.network.hwaddr = 00:16:3e:xx:xx:xx
    lxc.network.flags = up
    lxc.network.mtu = 1500

Start the LXC container:

    lxc-start -d --name osic-prep

### Setup LXC Container

Attach to the LXC container:

    lxc-attach --name osic-prep

Install the necessary packages:

    apt-get update

    apt-get install \
    cobbler \
    dhcp3-server \
    git \
    python-dev \
    python-setuptools \
    sshpass \
    ipmitool

Install pip:

    easy_install pip

Install ansible and dependencies:

    pip install ansible markupsafe

Download the __osic-prep-ansible__ directory:

    cd /root

    git clone https://github.com/jameswthorne/osic-prep-ansible.git

Download the __rpc-prep-scripts__ directory:

    cd /root

    git clone https://github.com/jameswthorne/rpc-prep-scripts.git

Configure the DHCP server by running the following sed commands. You will need to change __172.22.0.22__ to match the IP address you assigned to eth1 inside the LXC container.

    sed -i '/^manage_dhcp: / s/ .*/ 1/' /etc/cobbler/settings

    sed -i '/^restart_dhcp: / s/ .*/ 1/' /etc/cobbler/settings

    sed -i '/^next_server: / s/ .*/ 172.22.0.22/' /etc/cobbler/settings

    sed -i '/^server: / s/ .*/ 172.22.0.22/' /etc/cobbler/settings

This should be set by default, but open __/etc/cobbler/modules.conf__ to verify the DHCP module is set to __manage_isc__:

    [dhcp]
    module = manage_isc

Open __/etc/default/isc-dhcp-server__ and configure the interface for the DHCP server to listen on:

    INTERFACES="eth1"

Open __/etc/cobbler/dhcp.template__ and configure your DHCP settings. You will need to change the __subnet__, __netmask__, __option routers__, __option subnet-mask__, and __range dynamic-bootp__ parameters to match your network.

    subnet 172.22.0.0 netmask 255.255.252.0 {
         option routers             172.22.0.1;
         option domain-name-servers 8.8.8.8;
         option subnet-mask         255.255.252.0;
         range dynamic-bootp        172.22.0.23 172.22.0.100;
         default-lease-time         21600;
         max-lease-time             43200;
         next-server                $next_server;

At this point, Cobbler is configured, but there is nothing to PXE boot from. The modified Ubuntu Server 14.04 ISO needs to be downloaded. However, LXC containers cannot mount ISOs, so the Ubuntu ISO will be downloaded to the build host, mounted, then the data copied to the LXC container using rsync.

Now, exit the LXC container:

    exit

Back on the build host, begin downloading the modified Ubuntu Server 14.04.3 ISO:

    wget http://public.thornelabs.net/ubuntu-14.04.3-server-i40e-hp-raid-x86_64.iso

In another terminal window on the build host, copy the build host's SSH public key in __/root/.ssh/id_rsa.pub__ and re-attach to the LXC container:

    lxc-attach --name osic-prep

rsync will be used to transfer the ISO contents to the LXC container, so install and start SSH:

    apt-get install openssh-server

    service ssh start

First, create the __.ssh__ directory and set proper permissions:

    mkdir -p /root/.ssh

    chmod 700 /root/.ssh

Create the __authorized_keys__ file and set proper permissions:

    touch /root/.ssh/authorized_keys

    chmod 640 /root/.ssh/authorized_keys

Open file __/root/.ssh/authorized_keys__ and paste the SSH public key from the build host to it.

Finally, create a directory for the data:

    mkdir -p /root/ubuntu-14.04.3-server-i40e-hp-raid-x86_64

Exit the LXC container again:

    exit

Back on the build host, the Ubuntu ISO should have downloaded. Mount it:

    mount -o loop ubuntu-14.04.3-server-i40e-hp-raid-x86_64.iso /mnt

Copy the mounted ISO contents to the LXC container. You will probably need to change the container's IP address, 10.0.3.223 in this example, to match your own. Find the container's private IP address by running `lxc-info --name osic-prep | grep IP` and use the __10.0.X.X__ IP address:

    rsync -a --stats --progress /mnt/* 10.0.3.223:/root/ubuntu-14.04.3-server-i40e-hp-raid-x86_64/

Unmount the Ubuntu ISO from the host:

    umount /mnt

Reattach to the LXC container:

    lxc-attach --name osic-prep

Uninstall the SSH server:

    apt-get purge openssh-server

Import the Ubuntu ISO into cobbler:

    cobbler import --name=ubuntu-14.04.3-server-i40e-hp-raid-x86_64 --path=/root/ubuntu-14.04.3-server-i40e-hp-raid-x86_64

Now that the data is imported, you can delete the directory:

    rm -rf /root/ubuntu-14.04.3-server-i40e-hp-raid-x86_64
    
Create a fresh __authorized_keys__ file and set the proper permissions:

    rm /root/.ssh/authorized_keys

    touch /root/.ssh/authorized_keys

    chmod 640 /root/.ssh/authorized_keys

Cobbler will rewrite provisioned Ubuntu server's apt sources.list file to point to the Cobbler server. The Cobbler server will not have the most up-to-date packages, so there is a command in the Preseed file that will overwrite the sources.list file to be a normal Ubuntu one.

Download the default Ubuntu sources.list file:

    wget https://raw.githubusercontent.com/jameswthorne/default-ubuntu-sources.list/master/trusty-sources.list -O /var/www/html/trusty-sources.list

The default Ubuntu Preseed is not unattended. Download the following Preseeds which are all unattended:

    cd /opt
    
    git clone https://github.com/jameswthorne/osic-preseeds.git

There are many different RAID array types. Setup the following Cobbler Profiles so you can use any of them:

    cobbler profile add \
    --name ubuntu-14.04.3-server-unattended-osic-generic \
    --distro ubuntu-14.04.3-server-i40e-hp-raid-x86_64 \
    --kickstart /opt/osic-preseeds/ubuntu-server-14.04-unattended-cobbler-osic-generic.seed

    cobbler profile add \
    --name ubuntu-14.04.3-server-unattended-osic-generic-ssd \
    --distro ubuntu-14.04.3-server-i40e-hp-raid-x86_64 \
    --kickstart /opt/osic-preseeds/ubuntu-server-14.04-unattended-cobbler-osic-generic-ssd.seed

    cobbler profile add \
    --name ubuntu-14.04.3-server-unattended-osic-cinder \
    --distro ubuntu-14.04.3-server-i40e-hp-raid-x86_64 \
    --kickstart /opt/osic-preseeds/ubuntu-server-14.04-unattended-cobbler-osic-cinder.seed

    cobbler profile add \
    --name ubuntu-14.04.3-server-unattended-osic-cinder-ssd \
    --distro ubuntu-14.04.3-server-i40e-hp-raid-x86_64 \
    --kickstart /opt/osic-preseeds/ubuntu-server-14.04-unattended-cobbler-osic-cinder-ssd.seed

    cobbler profile add \
    --name ubuntu-14.04.3-server-unattended-osic-swift \
    --distro ubuntu-14.04.3-server-i40e-hp-raid-x86_64 \
    --kickstart /opt/osic-preseeds/ubuntu-server-14.04-unattended-cobbler-osic-swift.seed

    cobbler profile add \
    --name ubuntu-14.04.3-server-unattended-osic-swift-ssd \
    --distro ubuntu-14.04.3-server-i40e-hp-raid-x86_64 \
    --kickstart /opt/osic-preseeds/ubuntu-server-14.04-unattended-cobbler-osic-swift-ssd.seed

Restart and Sync Cobbler

    service cobbler restart

    cobbler sync

Clean up various things to make a clean image:

    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

    rm -f /var/log/wtmp /var/log/btmp

    history -c

Now you need to package up the LXC container. Exit the LXC container:

    exit

### Package Up the LXC Container

Stop the LXC container:

    lxc-stop --name osic-prep

Tar up the LXC container:

    cd /var/lib/lxc

    tar --numeric-owner -cvzf /root/osic-prep-lxc-container.tar.gz osic-prep

Finally, upload the tar'd LXC container to Cloud Files so it can be accessed from customer environments by the Implementation Team.
