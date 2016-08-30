=======================
OSIC deployment process
=======================

.. toctree::
   maxdepth: 2
   
   provision-deploy-host.rst
   download-container.rst
   pxe-boot-servers.rst
   bootstrap-servers.rst

Overview
~~~~~~~~

You have a number of bare metal servers and you want to build your own
cloud on top of them. To achieve that goal, first step is to have your
bare metal servers provisioned with an Operating system, most likely
Linux if you will be using later an Open Source platform to build your
cloud. On a production deployment, the process of deploying all these
servers starts by manually provisioning the first host from your
servers. This host will become your deployment host and will be used
later to provision the rest of the servers by booting them over Network.
This mechanism is called PXE Booting where servers use their PXE-enabled
Network Interface Cards to boot from them as any other boot device.
