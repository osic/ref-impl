==============================================
Download and setup the osic-prep LXC container
==============================================

With the deployment host provisioning done, SSH to it.

Next, you will download a pre-packaged LXC container that contains a
tool you need to PXE boot the rest of the servers called Cobbler

Cobbler overview
~~~~~~~~~~~~~~~~

There is a numerous tools that implement the PXE mechanism. However, we
decided here to use Cobbler since it is a powerful, easy to use and
handy when it comes to quickly setting up network installation
environments. Cobbler is a Linux based provisioning system which lets
you, among other things, configure Network installation for each server
from its MAC address, manage DNS and serve DHCP requests, etc.

Setup LXC linux bridge
~~~~~~~~~~~~~~~~~~~~~~

In order to use the LXC container, a new bridge will need to be created:
**br-pxe**.

**NOTE: Follow these instructions very carefully.**

First, install the necessary packages:

::

    apt-get install vlan bridge-utils

Reconfigure the network interface file **/etc/network/interfaces** to
match the following (your IP addresses and ports will most likely be
different):

::

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

Bring up **br-pxe**. I recommend you have access to the iLO in case the
following commands fail and you lose network connectivity:

::

    ifdown p1p1; ifup br-pxe

Install and configure the LXC container
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Install the necessary LXC package:

::

    apt-get install lxc

Change into root's home directory:

::

    cd /root

Download the LXC container to the deployment host:

::

    wget http://23.253.105.87/osic.tar.gz

Untar the LXC container:

::

    tar xvzf /root/osic.tar.gz

Move the LXC container directory into the proper directory:

::

    mv /root/osic-prep /var/lib/lxc/

Once moved, the LXC container should be stopped, verify by running
``lxc-ls -f``. Before starting it, open
**/var/lib/lxc/osic-prep/config** and change **lxc.network.ipv4 =
172.22.0.22/22** to a free IP address from the PXE network you are
using. Do not forget to set the CIDR notation as well. If your PXE
network already is **172.22.0.22/22**, you do not need to make further
changes.

::

    lxc.network.type = veth
    lxc.network.name = eth1
    lxc.network.ipv4 = 172.22.0.22/22
    lxc.network.link = br-pxe
    lxc.network.hwaddr = 00:16:3e:xx:xx:xx
    lxc.network.flags = up
    lxc.network.mtu = 1500

Start the LXC container:

::

    lxc-start -d --name osic-prep

You should be able to ping the IP address you just set for the LXC
container from the host.

Configure LXC container
~~~~~~~~~~~~~~~~~~~~~~~

There are a few configuration changes that need to be made to the
pre-packaged LXC container for it to function on your network.

Start by attaching to the LXC container:

::

    lxc-attach --name osic-prep

If you had to change the IP address above, reconfigure the DHCP server
by running the following sed commands. You will need to change
**172.22.0.22** to match the IP address you set above:

::

    sed -i '/^next_server: / s/ .*/ 172.22.0.22/' /etc/cobbler/settings

    sed -i '/^server: / s/ .*/ 172.22.0.22/' /etc/cobbler/settings

Open **/etc/cobbler/dhcp.template** and reconfigure your DHCP settings.
You will need to change the **subnet**, **netmask**, **option routers**,
**option subnet-mask**, and **range dynamic-bootp** parameters to match
your network.

::

    subnet 172.22.0.0 netmask 255.255.252.0 {
         option routers             172.22.0.1;
         option domain-name-servers 8.8.8.8;
         option subnet-mask         255.255.252.0;
         range dynamic-bootp        172.22.0.23 172.22.0.200;
         default-lease-time         21600;
         max-lease-time             43200;
         next-server                $next_server;

Finally, restart Cobbler and sync it:

::

    service cobbler restart

    cobbler sync

At this point you can PXE boot any servers, but it is still a manual
process. In order for it to be an automated process, a CSV file needs to
be created.
