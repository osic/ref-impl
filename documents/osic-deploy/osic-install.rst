Install LXC and Configure LXC Container
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