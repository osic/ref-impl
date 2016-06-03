Reference Implementation (OSA) Deployment Process
=======================

Table of Contents
-----------------
* [Intro](#Intro)
* [Prepare deployment host](#Prepare deployment host)
* [Prepare target hosts](#Prepare target hosts)
* [Configuring OpenStack environment](#Configuring OpenStack environment)
* [OpenStack Installation](#OpenStack Installation)

Intro
------

This document summarizes the steps to deploy an openstack cloud from the openstack_ansible documentation. If you want to customize your deployment, please visit the openstack_ansible documentation website at [OSA](http://docs.openstack.org/developer/openstack-ansible/install-guide/)

#### Environment

By end of this chapter, keeping current configurations you will have an OpenStack environment composed of:
- One deployment host
- Eight compute hosts
- Three logging hostsm
- Three infrastructure hosts
- Three cinder hosts
- Three swift hosts

Network layout between nodes will be as follows:

| Network type       | Subnet          | Vlan     |
|--------------------|-----------------|----------|
| HOSTS Network      | 172.22.0.0/22   | untagged |
| MANAGEMENT Network | 172.22.100.0/22 | 830      |
| STORAGE Network    | 172.22.104.0/22 | 831      |
| OVERLAY Network    | 172.22.108.0/22 | 832      |
| FLAT Network       | 172.22.112.0/22 | 833      |



Prepare deployment host
-----------------------

#### configure operating system
Install necessary packages for deployment:

    apt-get install aptitude build-essential git ntp ntpdate openssh-server python-dev sudo

#### install source and dependencies
In the deployment host, clone the osic-ref-impl repo into /opt/osic-ref-impl

    git clone https://github.com/raddaoui/osic-ref-impl.git /opt/osic-ref-impl

Also, clone OSA repository into /opt/openstack_ansible

  git clone -b TAG https://github.com/openstack/openstack-ansible.git /opt/openstack-ansible

Change to /opt/openstack-ansible directory

    cd /opt/openstack-ansible

Run the Ansible bootstrap script to install ansible and all necessary roles for OSA:

    scripts/bootstrap-ansible.sh

Copy the pair of public/private key used in the osic-prep container in /root/.ssh/ directory:

    cp /var/lib/lxc/osic-prep/rootfs/root/.ssh/id_rsa* /root/.ssh/

copy the hosts inventory from the osic-prep container to /opt/osic-ref-impl/playbooks/inventory:

    cp /var/lib/lxc/osic-prep/rootfs/root/osic-prep-ansible/hosts /opt/osic-ref-impl/playbooks/inventory/inventory/static-inventory.yml

#### configure Network for deployment host

Move to the playbooks directory from the osic-ref-impl root directory:

    cd /opt/osic-ref-impl/playbooks

Configure networking on the deployment host to have an interface on the same network allocated for container management. This interface will be used to connect and manage all target hosts and their hosted containers that will be created later by OSA.

    ansible-playbook -i inventory/static-inventory.yml create-network-interfaces.yml -e "target=deploy"

Prepare target hosts
-----------------------

#### Configuring the operating system

Install software packages and load necessary dynamic kernel modules for networking:

    ansible-playbook -i inventory/static-inventory.yml bootstrap.yml

#### configure Network for target hosts

Setup bonded interfaces and add bridges to target hosts to separate different traffics in vlans.

    ansible-playbook -i inventory/static-inventory.yml create-network-interfaces.yml -e "target=all"

This command will reboot servers once it finish configurations!

#### Setting up storage devices.

First, Determine storage devices on nodes that will be used for object storage, you can use commands like parted, fdisk or see directly in the /dev/ directory to find available disks.
Then, list all disks under disks list in ./vars/swift-disks.yml

    disks:
      - sdb
      - sdc
      - ...


Format disks for Swift to the XFS file sytem and mount them to /srv/node on each host by running the following playbook:

    ansible-playook -i inventory/static-inventory.yml swift-disks-prepare.yml


Configuring OpenStack environment
----------------------------------

Copy OSA configuration files for our environment to /etc/openstack_deploy:

    cp -r /opt/osic-ref-impl/openstack_deploy /etc/openstack_deploy


Change to /etc/openstack_deploy:

    cd /etc/openstack_deploy

Check conf.d directory and edit files there to configure target hosts to match your environment (compute, log_hosts, storage_hosts, network_hosts...).

Configure service credentials by filling the user_secrets.yml manually or through OSA provided script:

    cd /opt/openstack-ansible/scripts
    python pw-token-gen.py --file /etc/openstack_deploy/user_secrets.yml

OpenStack Installation
-----------------------

move to openstack-ansible repository:

    cd /opt/openstack-ansible

Setup target hosts for infrastructure and OpenStack services by running the setup-hosts.yml foundation playbooks

    cd /opt/openstack-ansible/playbooks
    openstack-ansible setup-hosts.yml

Run the Infratructure playbook to install the infrastructure services (Memcached, the repository server, Galera, Rabbitmq...)

    openstack-ansible setup-infrastructure.yml

Install OpenStack services (keystone, glane, cinder, nova, neutron, heat, horizon, ceilometer, swift)

    openstack-ansible setup-openstack.yml


Congratulation! you have your OpenStack cluster running.

