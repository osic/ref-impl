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

Network layout between nodes will be as follows but you most likely will need to change them according to your provided networks:

| Network type       | Subnet          | Vlan     |
|--------------------|-----------------|----------|
| HOSTS Network      | 172.22.0.0/22   | untagged |
| MANAGEMENT Network | 172.22.100.0/22 | 830      |
| STORAGE Network    | 172.22.104.0/22 | 831      |
| OVERLAY Network    | 172.22.108.0/22 | 832      |
| FLAT Network       | 172.22.112.0/22 | 833      |



Prepare deployment host
-----------------------

If you are still in the osic-prep container, exit to the host.

#### configure operating system
Install necessary packages for deployment:

    apt-get install aptitude build-essential git ntp ntpdate openssh-server python-dev sudo

#### install source and dependencies
In the deployment host, clone the ref-impl repo into /opt/osic-ref-impl

    git clone https://github.com/osic/ref-impl.git /opt/osic-ref-impl

Also, clone OSA repository into /opt/openstack_ansible

    git clone -b stable/mitaka https://github.com/openstack/openstack-ansible.git /opt/openstack-ansible

Change to /opt/openstack-ansible directory

    cd /opt/openstack-ansible

Run the Ansible bootstrap script to install ansible and all necessary roles for OSA:

    scripts/bootstrap-ansible.sh

Copy the pair of public/private key used in the osic-prep container in /root/.ssh/ directory:

    cp /var/lib/lxc/osic-prep/rootfs/root/.ssh/id_rsa* /root/.ssh/

copy the hosts inventory from the osic-prep container to /opt/osic-ref-impl/playbooks/inventory:

    cp /var/lib/lxc/osic-prep/rootfs/root/osic-prep-ansible/hosts /opt/osic-ref-impl/playbooks/inventory/static-inventory.yml

Make sure you include the deployment host in __static-inventory.yml__ as follows:

    [deploy]
    729429-deploy01 ansible_ssh_host=172.22.0.21

Copy all of the servers SSH fingerprints from the LXC container osic-prep known_hosts file.

    cp /var/lib/lxc/osic-prep/rootfs/root/.ssh/known_hosts /root/.ssh/known_hosts

Copy public key to authorized_key file in deployment host to allow ssh locally

    cat /root/.ssh/id_rsa.pub > /root/.ssh/authorized_keys

Prepare target hosts
-----------------------

#### Configuring the operating system

Move to the playbooks directory from the osic-ref-impl root directory:

    cd /opt/osic-ref-impl/playbooks

Install software packages and load necessary dynamic kernel modules for networking:

    ansible-playbook -i inventory/static-inventory.yml bootstrap.yml

#### Setting up storage devices.

First, Determine storage devices on nodes that will be used for object storage. To do that, login to one of the swift nodes, list all disks by executing __sudo fdisk -l__. Available disks will be in the form of __/dev/sd\<x>__ except __dev/sda__ since it hosts the Operating System.

If you still on the swift node, log out and return to your deployment node under __/opt/osic-ref-impl/playbooks__ directory and add the correct disks names under disks list in __./vars/swift-disks.yml__

    disks:
      - sdb
      - sdc
      - ...


Format disks for Swift to the XFS file sytem and mount them to /srv/node on each host by running the following playbook:

    ansible-playbook -i inventory/static-inventory.yml swift-disks-prepare.yml


#### configure Network for target hosts (deployment included)

This section will setup bonded interfaces and add bridges to target hosts to separate different traffics in vlans.

Deployment host should also have an interface on the same network allocated for container management. This interface will be used to connect and manage all target hosts and their hosted containers that will be created later by OSA.

For its deployment OSA uses usually 3 networks to separate traffic between containers, hosts and VMs:

* Management Network which provides management of and communication among infrastructure and OpenStack services.
* Tunnel (VXLAN) Network	which provides infrastructure for VXLAN tunnel networks.
* Storage Network which provides segregated access to Block Storage devices between Compute and Block Storage hosts.
* Flat Network (optional) if you want to use openstack networking flat (untagged network).

For that OSA will need a bridge on each host belonging to these networks. To do that, executing the playbook below will create these bridges with ip addresses of each bridge constructed by taking the last byte from the PXE ip address of the host and append it to the bridge network. For example if your host has 172.22.0.21 for its PXE interface, and if you configure your management_network to be 172.22.100.0/22, this playbook will create br-mgmt with its ip address equal to 172.22.100.__21__

Now, first open __/opt/osic-ref-impl/playbooks/vars/vlan_network_mapping.yml__ file and change settings there to match your network configurations.

Then execute the following command:

    ansible-playbook -i inventory/static-inventory.yml create-network-interfaces.yml

__Note:__ This command will reboot all the servers!



Configuring OpenStack environment
----------------------------------

Copy OSA configuration files for our environment to /etc/openstack_deploy:

    cp -rf /opt/osic-ref-impl/openstack_deploy /etc/


Change to /etc/openstack_deploy:

    cd /etc/openstack_deploy

1. Open openstack_user_config.yml file and edit:
   * __cidr_networks__ to match your network configurations (these terms are usually mingled: Management and container networks, overlay and tunnel networks)
   * __used_ips__ to exclude ip addresses from usage by OSA(ip addresses used by servers should be included here).
   * __internal_lb_vip_address__ and __external_lb_vip_address__ to ip addresses of one of the controller nodes belonging to Management and Flat Network respectively.

2. Move to __conf.d__ directory and edit:
   * ip addresses of different hosts under compute_hosts, log_hosts, storage_hosts, network_hosts... to their ip addresses of the interface belonging to the management network (__infra hosts__ hosting infrastructure services are usually referencing controller hosts.)
   * storage devices of your swift nodes you previously determined under __drives__ in __swift.yml__.


Configure service credentials by filling the user_secrets.yml manually or through OSA provided script:

    cd /opt/openstack-ansible/scripts
    python pw-token-gen.py --file /etc/openstack_deploy/user_secrets.yml

OpenStack Installation
-----------------------

move to openstack-ansible repository:

    cd /opt/openstack-ansible/playbooks

Setup target hosts for infrastructure and OpenStack services by running the setup-hosts.yml foundation playbooks

    openstack-ansible setup-hosts.yml

Run the Infratructure playbook to install the infrastructure services (Memcached, the repository server, Galera, Rabbitmq...)

    openstack-ansible setup-infrastructure.yml

Install OpenStack services (keystone, glane, cinder, nova, neutron, heat, horizon, ceilometer, swift)

    openstack-ansible setup-openstack.yml


Congratulation! you have your OpenStack cluster running.
