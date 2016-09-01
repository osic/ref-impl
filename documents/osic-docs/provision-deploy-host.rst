================================
Provisioning the deployment host
================================

Integrated Lights-Out (ILO) overview
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Integrated Lights-Out (ILO) is a card integrated to the motherboard in
most HP ProLiant servers. This allows users to remotely configure,
monitor, and connect to servers even though no operating system (OS) is
installed. This is called out-of-band management. ILO has its own
network interface and is commonly used for:

* Power control of the server
* Mount physical CD/DVD drive or image remotely
* Request an Integrated Remote Console for the server
* Monitor server health

Manually provision the deployment host
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#. Download the `modified Ubuntu Server 14.04.3 ISO <http://23.253.105.87/ubuntu-14.04.3-server-i40e-hp-raid-x86_64.iso>`_.

   .. note::

      The modified Ubuntu Server ISO contains i40e driver version 1.3.47 and
      HP iLO tools.

#. Boot the deployment host to this ISO using a USB drive, CD/DVD-ROM,
   iDRAC, or iLO.

#. (Optional) To deploy a host through ILO:
   
   #. Open a web browser and browse to the host's ILO IP address.
   #. Login with the ILO credentials.                                                                         
   #. Request a remote console from the GUI. 
      
      .. note::
         
         This is a .NET console for windows or Java console for other OSes.

   #. To deploy the server, select ``Virtual Drives`` the ILO
      console.
   #. Press ``Image File CD/DVD-ROM`` then select the Ubuntu image you
      downloaded to your local directory.

      .. note::

         Depending on your browser and OS, If you are using the Java console,
         you may need to allow your java plugin to run in unsafe mode, so that
         it can access the ubuntu image from your local directory.

   #. Click ``Power Switch`` and select ``Reset`` to reboot the
      host from the image.

#. Ensure you have unselected the Ubuntu ISO from the ILO console
   (unselect Image File CD/DVD-ROM from the Virtual Drives tab). This ensures
   future server reboots do not continue to use it to boot.

Once the deployment host is booted to the ISO, follow these steps to
begin installation:

#. Select ``Language``.

#. Hit ``Fn`` and ``F6``.

#. Dismiss the `Expert` mode menu by hitting the ``Esc`` key.

#. Delete ``file=/cdrom/preseed/ubuntu-server.seed`` from the beginning of the
   line.

#. Insert ``preseed/url=http://23.253.105.87/osic.seed`` in its place.

#. Hit ``Enter`` to begin the install process. The console may appear to
   freeze for sometime.

#. You will receive the following menu prompts:

   * `Select a language`
   * `Select your location`
   * `Configure the keyboard`
   * `Configure the network`

DHCP detection will fail. You will need to manually select the proper
network interface - typically **p1p1** - and manually configure
networking on the **PXE** network (refer to your onboarding email to
find the **PXE** network information).

#. At the prompt for name servers, insert: `8.8.8.8 8.8.4.4`.

#. An error will appear stating: "``/dev/sda`` contains GPT signatures".
   This indicates that it had a GPT table. If you encounter this error
   select, ``No`` and continue.

#. Once networking is configured, the Preseed file will be downloaded. The
   remainder of the Ubuntu install will be unattended.

   .. note::

      The Ubuntu install will be finished when the system reboots and a login
      prompt appears.

Update Linux kernel
~~~~~~~~~~~~~~~~~~~

Once the system boots, SSH into it to using the IP address you
manually assigned.

#. Login with username ``root`` and password ``cobbler``.

#. Update the Linux kernel on the deployment host to get an updated upstream
   i40e driver.

   .. code:: console

      apt-get update; apt-get install -y linux-generic-lts-xenial

#. After the update finishes, reboot the server.
