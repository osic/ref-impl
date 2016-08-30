================================
Provisioning the deployment host
================================

ILO overview
~~~~~~~~~~~~

ILO or Integrated Lights-Out, is a card integrated to the motherboard in
most HP ProLiant servers which allows users to remotely configure,
monitor and connect to servers even though no Operating System is
installed, usually called out-of-band management. ILO has its own
network interface and is commonly used for:

-  Power control of the server
-  Mount physical CD/DVD drive or image remotely
-  Request an Integrated Remote Console for the server
-  Monitor server health

Manually provision the deployment host
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

First, download a `modified Ubuntu Server 14.04.3
ISO <http://23.253.105.87/ubuntu-14.04.3-server-i40e-hp-raid-x86_64.iso>`__.
The modified Ubuntu Server ISO contains i40e driver version 1.3.47 and
HP iLO tools.

Boot the deployment host to this ISO using a USB drive, CD/DVD-ROM,
iDRAC, or iLO. Whatever is easiest.

**NOTE:** to deploy a host through ILO:

1. Open a web browser and browse to the host's ILO IP address.
2. Login with the ILO credentials
3. Request a **remote console** from the GUI (.NET console for windows
   or Java console for other OSes).
4. To deploy the server, select the **Virtual Drives** tab from the ILO
   console, press **Image File CD/DVD-ROM** then select the Ubuntu image
   you downloaded to your local directory. Depending on your browser and
   OS, If you are using the Java console, you may need to allow your
   java plugin to run in unsafe mode, so that it can access the ubuntu
   image from your local directory.
5. Click the **Power Switch** tab and select **Reset** to reboot the
   host from the image.

**Before you move on, be sure you have unselected or removed the Ubuntu
ISO from the ILO console (unselect Image File CD/DVD-ROM from the
Virtual Drives tab)** so that future server reboots do not continue to
use it to boot.

Once the deployment host is booted to the ISO, follow these steps to
begin installation:

1. Select **Language**

2. Hit **Fn + F6**

3. Dismiss the **Expert mode** menu by hitting **Esc**.

4. Scroll to the beginning of the line and delete
   ``file=/cdrom/preseed/ubuntu-server.seed``.

5. Type ``preseed/url=http://23.253.105.87/osic.seed`` in its place.

6. Hit **Enter** to begin the install process. The console may appear to
   freeze for sometime.

7. You will (eventually) be prompted for the following menus:

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

Update Linux kernel
~~~~~~~~~~~~~~~~~~~

Once the system boots, it can be SSH'd to using the IP address you
manually assigned. Login with username **root** and password
**cobbler**.

You will need to update the Linux kernel on the deployment host in order
to get an updated upstream i40e driver.

::

    apt-get update; apt-get install -y linux-generic-lts-xenial

When the update finishes running, **reboot** the server and proceed with
the rest of the guide.
