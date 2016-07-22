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
