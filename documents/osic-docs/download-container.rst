==============================================
Download and setup the osic-prep LXC container
==============================================

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
~~~~~~~~~~~~~~~~~~~~~~

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

   .. code::

      ifdown p1p1
      ifup br-pxe

Install LXC and configure LXC container
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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
~~~~~~~~~~~~~~~~~~~~~~~

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

      service cobbler restart

      cobbler sync

You can now manually PXE boot any servers.