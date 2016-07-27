Provisioning the Deployment Host
--------------------------------

You have been allocated a certain number of bare metal servers. There is
currently nothing running on these servers. You will need to manually
provision the first host. This will become your deployment host that
will be used to provision the rest of the servers using PXE.

Manually Provision the Deployment Host
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

First, download a `modified Ubuntu Server 14.04.3
ISO <http://23.253.105.87/ubuntu-14.04.3-server-i40e-hp-raid-x86_64.iso>`__.
The modified Ubuntu Server ISO contains i40e driver version 1.3.47 and
HP iLO tools.

Boot the deployment host to this ISO using a USB drive, CD/DVD-ROM,
iDRAC, or iLO. Whatever is easiest.

**NOTE:** to get an access to a server console through ILO, simply look
for the host ILO ip address through a web browser, login with the
credentials provided and then you can request a remote console from the
GUI. After, to deploy the server, select the **Virtual Drives** tab from
the ILO console, press **Image File CD/DVD-ROM**, select the Ubuntu
image you downloaded to your local directory and finally press on the
**Power Switch** tab and select **Reset** to reboot the host from the
image.

**Before you move on, be sure you have unselected or removed the Ubuntu
ISO from the ILO console (unselect Image File CD/DVD-ROM from the
Virtual Drives tab)** so that future server reboots do not continue to
use it to boot.

Once the deployment host is booted to the ISO, follow these steps to
begin installation:

1. Select **Language**

2. Hit **Fn + F6**

3. Dismiss the **Expert mode** menu by hiting **Esc**.

4. Scroll to the beginning of the line and delete
   **file=/cdrom/preseed/ubuntu-server.seed**.

5. Type **preseed/url=http://23.253.105.87/osic.seed**

6. Hit **Enter** to begin the install process.

7. You will be prompted for the following menus:

-  Select a language
-  Select your location
-  Configure the keyboard
-  Configure the network

DHCP detection will fail. You will need to manually select the proper
network interface - typically **p1p1** - and manually configure
networking on the **PXE** network (refer to your onboarding email to
find the **PXE** network information). When asked for name servers, type
8.8.8.8 8.8.4.4.

You may see an error stating: "/dev/sda" contains GPT signatures,
indicating that it had a GPT table... Is this a GPT partition table? If
you encounter this error select "No" and continue.

Once networking is configured, the Preseed file will be downloaded. The
remainder of the Ubuntu install will be unattended.

The Ubuntu install will be finished when the system reboots and a login
prompt appears.

Update Linux Kernel
~~~~~~~~~~~~~~~~~~~

Once the system boots, it can be SSH'd to using the IP address you
manually assigned. Login with username **root** and password
**cobbler**.

You will need to update the Linux kernel on the deployment host in order
to get an updated upstream i40e driver.

::

    apt-get update; apt-get install -y linux-generic-lts-xenial

When the update finishes running, reboot the server and proceed with the
rest of the guide.

Download and Setup the osic-prep LXC Container
----------------------------------------------

With the deployment host provisioning done, SSH to it.

Next, you will download a pre-packaged LXC container that contains
everything you need to PXE boot the rest of the servers.

Setup LXC Linux Bridge
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
