==============
Installing LXC
==============

#. Install the required LXC package:

   .. code::

      # apt-get install lxc

#. Change to the /root directory:

   .. code::

      # cd /root

#. Download the LXC container to the deployment host:

   .. code::

      # wget http://23.253.105.87/osic.tar.gz

#. Untar the LXC container:

   .. code::

      # tar xvzf /root/osic.tar.gz

#. Move the LXC container directory into the LXC directory:

   .. code::

      # mv /root/osic-prep /var/lib/lxc/

#. After you move it, the LXC container should be stopped. Verify this
   by running:

   .. code::

      # lxc-ls -f

#. Before starting the LXC container, edit
   ``/var/lib/lxc/osic-prep/config`` and change ``lxc.network.ipv4 =
   172.22.0.22/22`` to a free IP address from your PXE network.

   .. note::

      Remember to set the CIDR notation. If your PXE network already
      is ``172.22.0.22/22``, you do not need to make further changes.

   .. code::

      lxc.network.type = veth
      lxc.network.name = eth1
      lxc.network.ipv4 = 172.22.0.22/22
      lxc.network.link = br-pxe
      lxc.network.hwaddr = 00:16:3e:xx:xx:xx
      lxc.network.flags = up
      lxc.network.mtu = 1500

#. Start the LXC container:

   .. code::

      # lxc-start -d --name osic-prep

Verify that you can ping the IP address for the LXC container from the
host.
