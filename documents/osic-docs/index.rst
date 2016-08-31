=======================
OSIC deployment process
=======================

.. toctree::
   :maxdepth: 2

   provision-deploy-host.rst
   download-container.rst
   pxe-boot-servers.rst
   bootstrap-servers.rst

Overview
~~~~~~~~

The scenario for the following document assumes you have a number
of bare metal servers and want to build your own cloud on top of them.

This document recommends provisioning your bare metal servers with your
chosen operating system (OS). We recommend using a Linux OS if you later
want to use an Open Source platform to build your cloud.

In a production deployment, the process of deploying all
your servers starts by manual provisioning. The host will become your
deployment host and will be used later to provision the rest of your servers
by booting them over the network. This is called
`PXE Booting <https://en.wikipedia.org/wiki/Preboot_Execution_Environment>`_.
