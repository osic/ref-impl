Configure LXC Container
~~~~~~~~~~~~~~~~~~~~~~~

There are a few configuration changes that need to be made to the
pre-packaged LXC container for it to function on your network.

Start by attaching to the LXC container:

::

    lxc-attach --name osic-prep

If you had to change the IP address above, reconfigure the DHCP server
by running the following sed commands. You will need to change
**172.22.0.22** to match the IP address you set above:

::

    sed -i '/^next_server: / s/ .*/ 172.22.0.22/' /etc/cobbler/settings

    sed -i '/^server: / s/ .*/ 172.22.0.22/' /etc/cobbler/settings

Open **/etc/cobbler/dhcp.template** and reconfigure your DHCP settings.
You will need to change the **subnet**, **netmask**, **option routers**,
**option subnet-mask**, and **range dynamic-bootp** parameters to match
your network.

::

    subnet 172.22.0.0 netmask 255.255.252.0 {
         option routers             172.22.0.1;
         option domain-name-servers 8.8.8.8;
         option subnet-mask         255.255.252.0;
         range dynamic-bootp        172.22.0.23 172.22.0.200;
         default-lease-time         21600;
         max-lease-time             43200;
         next-server                $next_server;

Finally, restart Cobbler and sync it:

::

    service cobbler restart

    cobbler sync

At this point you can PXE boot any servers, but it is still a manual
process. In order for it to be an automated process, a CSV file needs to
be created.

PXE Boot the Servers
--------------------

Gather MAC Addresses
~~~~~~~~~~~~~~~~~~~~

Go to root home directory

::

    cd /root

You will need to obtain the MAC address of the network interface (e.g.
p1p1) configured to PXE boot on every server. Be sure the MAC addresses
are mapped to their respective hostname.

You can do this by logging into the LXC container and creating a CSV
file named **ilo.csv**. Use the information from your onboarding email
to create the CSV.

For example:

::

    729427-controller01,10.15.243.158,controller
    729426-controller02,10.15.243.157,controller
    729425-controller03,10.15.243.156,controller
    729424-logging01,10.15.243.155,logging
    729423-logging02,10.15.243.154,logging
    729422-logging03,10.15.243.153,logging
    729421-compute01,10.15.243.152,compute
    729420-compute02,10.15.243.151,compute
    729419-compute03,10.15.243.150,compute
    729418-compute04,10.15.243.149,compute
    729417-compute05,10.15.243.148,compute
    729416-compute06,10.15.243.147,compute
    729415-compute07,10.15.243.146,compute
    729414-compute08,10.15.243.145,compute
    729413-cinder01,10.15.243.144,cinder
    729412-cinder02,10.15.243.143,cinder
    729411-cinder03,10.15.243.142,cinder
    729410-swift01,10.15.243.141,swift
    729409-swift02,10.15.243.140,swift
    729408-swift03,10.15.243.139,swift

Be sure to remove any spaces in your CSV file. We also recommend
removing the deployment host you manually provisioned from this CSV so
you do not accidentally reboot the host you are working from.

Once this information is collected, it will be used to create another
CSV file that will be the input for many different steps in the build
process.

Create Input CSV
~~~~~~~~~~~~~~~~

Now, we will use a script to create a CSV named **input.csv** in the
following format.

::

    hostname,mac-address,host-ip,host-netmask,host-gateway,dns,pxe-interface,cobbler-profile

If this will be an openstack-ansible installation, it is recommended to
order the rows in the CSV file in the following order, otherwise order
the rows however you wish:

1. Controller nodes
2. Logging nodes
3. Compute nodes
4. Cinder nodes
5. Swift nodes

An example for openstack-ansible installations:

::

    744800-infra01.example.com,A0:36:9F:7F:70:C0,172.22.0.23,255.255.252.0,172.22.0.1,8.8.8.8,p1p1,ubuntu-14.04.3-server-unattended-osic-generic
    744819-infra02.example.com,A0:36:9F:7F:6A:C8,172.22.0.24,255.255.252.0,172.22.0.1,8.8.8.8,p1p1,ubuntu-14.04.3-server-unattended-osic-generic
    744820-infra03.example.com,A0:36:9F:82:8C:E8,172.22.0.25,255.255.252.0,172.22.0.1,8.8.8.8,p1p1,ubuntu-14.04.3-server-unattended-osic-generic
    744821-logging01.example.com,A0:36:9F:82:8C:E9,172.22.0.26,255.255.252.0,172.22.0.1,8.8.8.8,p1p1,ubuntu-14.04.3-server-unattended-osic-generic
    744822-compute01.example.com,A0:36:9F:82:8C:EA,172.22.0.27,255.255.252.0,172.22.0.1,8.8.8.8,p1p1,ubuntu-14.04.3-server-unattended-osic-generic
    744823-compute02.example.com,A0:36:9F:82:8C:EB,172.22.0.28,255.255.252.0,172.22.0.1,8.8.8.8,p1p1,ubuntu-14.04.3-server-unattended-osic-generic
    744824-cinder01.example.com,A0:36:9F:82:8C:EC,172.22.0.29,255.255.252.0,172.22.0.1,8.8.8.8,p1p1,ubuntu-14.04.3-server-unattended-osic-cinder
    744825-object01.example.com,A0:36:9F:7F:70:C1,172.22.0.30,255.255.252.0,172.22.0.1,8.8.8.8,p1p1,ubuntu-14.04.3-server-unattended-osic-swift
    744826-object02.example.com,A0:36:9F:7F:6A:C2,172.22.0.31,255.255.252.0,172.22.0.1,8.8.8.8,p1p1,ubuntu-14.04.3-server-unattended-osic-swift
    744827-object03.example.com,A0:36:9F:82:8C:E3,172.22.0.32,255.255.252.0,172.22.0.1,8.8.8.8,p1p1,ubuntu-14.04.3-server-unattended-osic-swift

To do just that, the following command will loop through each iLO IP
address in **ilo.csv** to obtain the MAC address of the network
interface configured to PXE boot and setup rest of information as well
as shown above:

**NOTE:** make sure to Set COUNT to the first usable address after
deployment host and container (ex. If you use .2 and .3 for deployment
and container, start with .4 controller1) and make sure to change
**host-ip,host-netmask,host-gateway** in the script
(**172.22.0.$COUNT,255.255.252.0,172.22.0.1**) to match your PXE network
configurations.

::

    COUNT=23
    for i in $(cat ilo.csv)
    do
        NAME=`echo $i | cut -d',' -f1`
        IP=`echo $i | cut -d',' -f2`
        TYPE=`echo $i | cut -d',' -f3`

        case "$TYPE" in
          cinder)
                SEED='ubuntu-14.04.3-server-unattended-osic-cinder'
                ;;
            swift)
                SEED='ubuntu-14.04.3-server-unattended-osic-swift'
                ;;
            *)
            SEED='ubuntu-14.04.3-server-unattended-osic-generic'
                ;;
        esac
        MAC=`sshpass -p calvincalvin ssh -o StrictHostKeyChecking=no root@$IP show /system1/network1/Integrated_NICs | grep Port1 | cut -d'=' -f2`
        #hostname,mac-address,host-ip,host-netmask,host-gateway,dns,pxe-interface,cobbler-profile
        echo "$NAME,${MAC//[$'\t\r\n ']},172.22.0.$COUNT,255.255.252.0,172.22.0.1,8.8.8.8,p1p1,$SEED" | tee -a input.csv

        (( COUNT++ ))
    done

**NOTE:** before you continue, make sure the generated script
**input.csv** has all the information as shown in the example above. In
case you run into some missing information, you may need to paste the
above command in a bash script and execute it.

Assigning a Cobbler Profile
~~~~~~~~~~~~~~~~~~~~~~~~~~~

The last column in the CSV file specifies which Cobbler Profile to map
the Cobbler System to. You have the following options:

-  ubuntu-14.04.3-server-unattended-osic-generic
-  ubuntu-14.04.3-server-unattended-osic-generic-ssd
-  ubuntu-14.04.3-server-unattended-osic-cinder
-  ubuntu-14.04.3-server-unattended-osic-cinder-ssd
-  ubuntu-14.04.3-server-unattended-osic-swift
-  ubuntu-14.04.3-server-unattended-osic-swift-ssd

Typically, you will use the
**ubuntu-14.04.3-server-unattended-osic-generic** Cobbler Profile. It
will create one RAID10 raid group. The operating system will see this as
**/dev/sda**.

The **ubuntu-14.04.3-server-unattended-osic-cinder** Cobbler Profile
will create one RAID1 raid group and a second RAID10 raid group. These
will be seen by the operating system as **/dev/sda** and **/dev/sdb**,
respectively.

The **ubuntu-14.04.3-server-unattended-osic-swift** Cobbler Profile will
create one RAID1 raid group and 10 RAID0 raid groups each containing one
disk. The HP Storage Controller will not present a disk to the operating
system unless it is in a RAID group. Because Swift needs to deal with
individual, non-RAIDed disks, the only way to do this is to put each
disk in its own RAID0 raid group.

You will only use the **ssd** Cobbler Profiles if the servers contain
SSD drives.

Generate Cobbler Systems
~~~~~~~~~~~~~~~~~~~~~~~~

With this CSV file in place, run the **generate\_cobbler\_systems.py**
script to generate a **cobbler system** command for each server and pipe
the output to ``bash`` to actually add the **cobbler system** to
Cobbler:

::

    cd /root/rpc-prep-scripts

    python generate_cobbler_system.py /root/input.csv | bash

Verify the **cobbler system** entries were added by running
``cobbler system list``.

Once all of the **cobbler systems** are setup, run ``cobbler sync``.

Begin PXE Booting
~~~~~~~~~~~~~~~~~

To begin PXE booting, reboot all of the servers with the following
command (if the deployment host is the first controller, you will want
to **remove** it from the **ilo.csv** file so you don't reboot the host
running the LXC container):

::

    for i in $(cat /root/ilo.csv)
    do
    NAME=$(echo $i | cut -d',' -f1)
    IP=$(echo $i | cut -d',' -f2)
    echo $NAME
    ipmitool -I lanplus -H $IP -U root -P calvincalvin power reset
    done

**NOTE:** if the servers are already shut down, you might want to change
**power reset** with **power on** in the above command.

As the servers finish PXE booting, a call will be made to the cobbler
API to ensure the server does not PXE boot again.

To quickly see which servers are still set to PXE boot, run the
following command:

::

    for i in $(cobbler system list)
    do
    NETBOOT=$(cobbler system report --name $i | awk '/^Netboot/ {print $NF}')
    if [[ ${NETBOOT} == True ]]; then
    echo -e "$i: netboot_enabled : ${NETBOOT}"
    fi
    done

Any server which returns **True** has not yet PXE booted.

**NOTE**: In case you want to re-pxeboot servers, make sure to clean old
settings from cobbler with the following command:

::

    for i in `cobbler system list`; do cobbler system remove --name $i; done;

Bootstrapping the Servers
-------------------------

When all servers finish PXE booting, you will now need to bootstrap the
servers.

Generate Ansible Inventory
~~~~~~~~~~~~~~~~~~~~~~~~~~

Start by running the ``generate_ansible_hosts.py`` Python script:

::

    cd /root/rpc-prep-scripts

    python generate_ansible_hosts.py /root/input.csv > /root/osic-prep-ansible/hosts

If this will be an openstack-ansible installation, organize the Ansible
**hosts** file into groups for **controller**, **logging**, **compute**,
**cinder**, and **swift**, otherwise leave the Ansible **hosts** file as
it is and jump to the next section.

An example for openstack-ansible installation:

::

    [controller]
    744800-infra01.example.com ansible_ssh_host=10.240.0.51
    744819-infra02.example.com ansible_ssh_host=10.240.0.52
    744820-infra03.example.com ansible_ssh_host=10.240.0.53

    [logging]
    744821-logging01.example.com ansible_ssh_host=10.240.0.54

    [compute]
    744822-compute01.example.com ansible_ssh_host=10.240.0.55
    744823-compute02.example.com ansible_ssh_host=10.240.0.56

    [cinder]
    744824-cinder01.example.com ansible_ssh_host=10.240.0.57

    [swift]
    744825-object01.example.com ansible_ssh_host=10.240.0.58
    744826-object02.example.com ansible_ssh_host=10.240.0.59
    744827-object03.example.com ansible_ssh_host=10.240.0.60

Verify Connectivity
~~~~~~~~~~~~~~~~~~~

The LXC container will not have all of the new server's SSH fingerprints
in its **known\_hosts** file. Programatically add them by running the
following command:

::

    for i in $(cat /root/osic-prep-ansible/hosts | awk /ansible_ssh_host/ | cut -d'=' -f2)
    do
    ssh-keygen -R $i
    ssh-keyscan -H $i >> /root/.ssh/known_hosts
    done

Verify Ansible can talk to every server (the password is **cobbler**):

::

    cd /root/osic-prep-ansible

    ansible -i hosts all -m shell -a "uptime" --ask-pass

Setup SSH Public Keys
~~~~~~~~~~~~~~~~~~~~~

Generate an SSH key pair for the LXC container:

::

    ssh-keygen

Copy the LXC container's SSH public key to the **osic-prep-ansible**
directory:

::

    cp /root/.ssh/id_rsa.pub /root/osic-prep-ansible/playbooks/files/public_keys/osic-prep

Bootstrap the Servers
~~~~~~~~~~~~~~~~~~~~~

Finally, run the bootstrap.yml Ansible Playbook:

::

    cd /root/osic-prep-ansible

    ansible-playbook -i hosts playbooks/bootstrap.yml --ask-pass

Clean Up LVM Logical Volumes
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If this will be an openstack-ansible installation, you will need to
clean up particular LVM Logical Volumes.

Each server is provisioned with a standard set of LVM Logical Volumes.
Not all servers need all of the LVM Logical Volumes. Clean them up with
the following steps.

Remove LVM Logical Volume **nova00** from the Controller, Logging,
Cinder, and Swift nodes:

::

    ansible-playbook -i hosts playbooks/remove-lvs-nova00.yml

Remove LVM Logical Volume **deleteme00** from all nodes:

::

    ansible-playbook -i hosts playbooks/remove-lvs-deleteme00.yml

Update Linux Kernel
~~~~~~~~~~~~~~~~~~~

Every server in the OSIC RAX Cluster is running two Intel X710 10 GbE
NICs. These NICs have not been well tested in Ubuntu and as such the
upstream i40e driver in the default 14.04.3 Linux kernel will begin
showing issues when you setup VLAN tagged interfaces and bridges.

In order to get around this, you must install an updated Linux kernel.

You can quickly do this by running the following commands:

::

    cd /root/osic-prep-ansible

    ansible -i hosts all -m shell -a "apt-get update; apt-get install -y linux-generic-lts-xenial" --forks 25

Reboot Nodes
~~~~~~~~~~~~

Finally, reboot all servers:

::

    ansible -i hosts all -m shell -a "reboot" --forks 25

Once all servers reboot, you can begin installing openstack-ansible.
