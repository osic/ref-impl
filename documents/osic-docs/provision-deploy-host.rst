================================
Provisioning the deployment host
================================

Integrated Lights-Out (iLO) is a card integrated to the motherboard in
most HP ProLiant servers. This allows users to remotely configure,
monitor, and connect to servers without an installed operating system (OS).
This is called out-of-band management. iLO has its own
network interface and is commonly used for:

* Power control of the server
* Mount physical CD/DVD drive or image remotely
* Request an Integrated Remote Console for the server
* Monitor server health

Accessing the OSIC Servers
~~~~~~~~~~~~~~~~~~~~~~~~~~

To access the OSIC servers, you must be connected to the OSIC VPN.
To do that, disconnect from any other VPN (corporate) you are connected
to, then you are required to install an F5's SSL VPN. The SSL VPN is a
browser plugin.

See the novice install email for information on how to connect to the OSIC VPN.

.. note::

   The Chrome web browser does not support automatic plugin installation.
   We recommend using Firefox, or Safari for Mac.
   
Manually provision the deployment host
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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
      the `Fx` keys enabled as standard function keys.

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
   This manually configures networking on the **PXE** network. You will need to 
   refer to your novice install email to find the **PXE** network information.

   #. At the prompt for name servers, insert: `8.8.8.8 8.8.4.4`.

   #. If you receive an error stating: "``/dev/sda`` contains GPT signatures",
      it indicates that it had a GPT table. If you encounter this error
      select, ``No`` and continue.

#. Once networking is configured, the preseed file will be downloaded.

The Ubuntu install will be finished when the system reboots and a login
prompt appears.

Update Linux kernel
~~~~~~~~~~~~~~~~~~~

#. Once the system boots, SSH into it to using the IP address you
   manually assigned.

#. Login with username ``root`` and password ``cobbler``.

#. Update the Linux kernel on the deployment host to get an updated upstream
   i40e driver.

   .. code:: console

      apt-get update
      apt-get install -y linux-generic-lts-xenial

#. After the update finishes, click ``Power Switch`` and select ``Reset``
   to reboot the server.
