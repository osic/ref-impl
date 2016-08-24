.. _osic-provisioning:

============
Overview
===========

You have a number of bare metal servers and you want to build your own 
cloud on top of them. To achieve that goal, first step is to have your 
bare metal servers provisioned with an Operating system, most likely 
Linux if you will be using later an Open Source platform to build your 
cloud. On a production deployment, the process of deploying all these 
servers starts by manually provisioning the first host from your servers.
This host will become your deployment host and will be used later to provision 
the rest of the servers by booting them over Network. This mechanism 
is called PXE Booting where servers use their PXE-enabled Network 
Interface Cards to boot from them as any other boot device.

================================
Provisioning the deployment host
================================

Learn how to manually provision your first deployment host using ILO and how to
provision the rest of your servers using PXE.

ILO overview
~~~~~~~~~~~~

ILO or Integrated Lights-Out, is a card integrated to the motherboard in most
HP ProLiant servers which allows users to remotely configure, monitor and connect 
to servers even though no Operating System is installed, usually called out-of-band management. 
ILO has its own network interface and is commonly used for:

#. Power control of the server
#. Mount physical CD/DVD drive or image remotely
#. Request an Integrated Remote Console for the server
#. Monitor server health

Manually provisioning the deployment host
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#. Download a `modified Ubuntu Server 14.04.3 ISO
   <http://23.253.105.87/ubuntu-14.04.3-server-i40e-hp-raid-x86_64.iso>`_.
   The modified Ubuntu Server ISO contains i40e driver version 1.3.47
   and HP iLO tools.

#. Boot the deployment host to this ISO using a USB drive, CD/DVD-ROM,
   iDRAC, or iLO.
   To get an access to a server console through iLO, find the host iLO IP
   address through a web browser:

   #. Log in with the credentials provided.
   #. Request a remote console from the GUI.
   #. To deploy the server, select the ``Virtual Drives`` tab from the
      iLO console, press ``Image File CD/DVD-ROM``, then select the
      Ubuntu image you downloaded to your local directory.
   #. Click the ``Power Switch`` tab and select ``Reset`` to reboot
      the host from the image.

#. Deselect or remove the Ubuntu ISO from the ILO console by
   deselecting the ``Image File CD/DVD-ROM`` from the ``Virtual
   Drives`` tab.

The deployment host is now booted to the ISO. Perform the following
steps to begin installation:

#. Select ``Language``.

#. Press ``Fn`` and ``F6`` on your keyboard.

#. Dismiss the ``Expert mode`` menu by pressing ``Esc``.

#. Scroll to the beginning of the line and delete
   ``file=/cdrom/preseed/ubuntu-server.seed``.

#. Type ``preseed/url=http://23.253.105.87/osic.seed``.

#. Press ``Enter`` to begin the installation process.

#. You are prompted for the following menus:

   *  Select a language
   *  Select your location
   *  Configure the keyboard
   *  Configure the network

#. DHCP detection fails. Manually select the proper network interface,
   typically ``p1p1``, and manually configure networking on the
   ``PXE`` network.

   .. note::

      Refer to your onboarding email to find the ``PXE`` network information.

#. Insert the following configuration for name servers: ``8.8.8.8
   8.8.4.4``.

#. If an error appears asking if ``/dev/sda contains GPT signatures``,
   select ``No`` and continue.

After networking is configured, the ``Preseed`` file is downloaded.
The remainder of the Ubuntu install is unattended. The Ubuntu install
finishes when the system reboots and a login prompt appears.

Updating the Linux kernel
~~~~~~~~~~~~~~~~~~~~~~~~~

After the system boots, connect using SSH to the IP address you
manually assigned.

#. Log in with user name ``root`` and password ``cobbler``.

#. Update the Linux kernel on the deployment host to update the upstream
   i40e driver.

   .. code::

      # apt-get update; apt-get install -y linux-generic-lts-xenial

#. Reboot the server after the update finishes running.

#. After provisioning the deployment host, connect to it using SSH.

#. Download a pre-packaged LXC container, which contains everything
   needed to PXE boot the rest of the servers.

Provisioning the servers with PXE
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#. To set up the LXC container, create ``br-pxe``.

#. Install the required packages:

   .. code::

      # apt-get install vlan bridge-utils

#. Edit the network interface file ``/etc/network/interfaces`` to
   match the following:

   .. note::

      Your individual IP addresses and ports will differ from the ones
      below.

   .. code::

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

#. Bring up the ``br-pxe`` interface:

   .. code::

      # ifdown p1p1; ifup br-pxe

   .. note::

      We recommend that you have access to the iLO if these commands
      fail and you lose network connectivity.
