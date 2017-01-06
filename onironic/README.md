#Overview

When setting up the 22 node deployment in cloud1(RegionTwo), we were presented with an environment very different from the normal cobbler/baremetal setup we normally deploy in. Here are just some of the differences.

1. We have 3 images available:

  - ubuntu 14.04.5
  - ubuntu 16.04.1
  - centos 7

2. We have 3 flavor's available:

  - osic-baremetal-comp (everthing not cinder, ceph or swift)
  - osic-baremetal-object (swift, ceph)
  - osic-baremetal-block (cinder)

3. We have no console(have to rekick if the image can't boot)

4. We have no access to the api(must use the horizon gui to deploy)

The information for the initial setup of an environment can be found here:

- https://github.com/osic/osic-clouds


## Getting started with the ironic environment

You can follow the steps on the github link above to log in, create a jumpbox, set up ssh access, set up your browser proxy config.  The jumpbox create is for ops. When handing off we will want to create another with a separate key for the team handling the tests. 

1. Create a key with ssh-keygen on the jumpbox after logging in.
2. Log into https://cloud1.osic.org (manager will provide credentials)
3. Click on the osic-ops-ironic dropdown and select 'RegionTwo'  (the jumpboxes will be on region1.  The deploy boxs and environment will be on regionTwo)
4. Click on 'Compute' -> 'Access & Security' -> 'Key Pairs' -> 'Import Key Pair'  
5. Call the key whatever you want and add the public key info from the jumpbox ssh key into the  'Public Key' section.  Click on 'Import Key Pair' after.



## Set up your deploy box and ssh key

1. Log into https://cloud1.osic.org (manager will provide credentials)
2. Click on the osic-ops-ironic dropdown and select 'RegionTwo'  (the jumpboxes will be on region1.  The deploy box and environment will be on regionTwo)
3. Click on 'Compute' -> 'Instances' -> 'Launch Instance'
  - Image 'baremetal-ubuntu-trusty'
  - Flavor 'osic-baremetal-comp'
  - Security Group 'ironic'
  - KeyPair 'Use the jumpbox key created earlier'
4. Log into the deploy box via ssh from the jumpbox using the ssh key created earlier.
5. Sudo up and use ssh-keygen to create ssh keys for the root user.
6. Click on 'Compute' -> 'Access & Security' -> 'Key Pairs' -> 'Import Key Pair'  
7. Call the key whatever you want and add the public key info from the deploy ssh key into the  'Public Key' section.  Click on 'Import Key Pair' after.


## Create your onmetal environment nodes

Go to 'Compute' -> 'Instances' and start spinning up nodes.  


Use the following flavors as needed.
  - 'osic-baremetal-object': swift and ceph devices.
  - 'osic-baremetal-block': cinder devices
  - 'osic-baremetal-comp': everything else

Make sure to use the 'deploy' box ssh key created earlier when setting these up.

I also used the 'iroinc' security group on each when setting these up.

It also looks like we have a limited number of each flavor.  On a 100 node build, I was able to get a max of 64 osic-baremetal-comp flavors, 21 osic-baremetal-block and 25 osic-baremetal-object flavors.


## Prepare the devices

Log into the deploy box via the jumpbox for the next set of steps


### Clone the ref-impl repo and edit the inventory manually from the ip info in horizon.

<code>
cd /opt
git clone https://github.com/osic/ref-impl.git
cd /opt/ref-impl/onironic
vi inventory/hosts
</code> 

```
[deploy]

deploy ansible_ssh_user=ubuntu ansible_ssh_host=172.30.243.128 flavor=osic-baremetal-comp


[controller]

infra-1 ansible_ssh_user=ubuntu ansible_ssh_host=172.30.243.213 flavor=osic-baremetal-comp
infra-2 ansible_ssh_user=ubuntu ansible_ssh_host=172.30.243.210 flavor=osic-baremetal-comp
infra-3 ansible_ssh_user=ubuntu ansible_ssh_host=172.30.243.212 flavor=osic-baremetal-comp

[compute-completed]

compute-1 ansible_ssh_user=ubuntu ansible_ssh_host=172.30.243.228 flavor=osic-baremetal-comp
compute-2 ansible_ssh_user=ubuntu ansible_ssh_host=172.30.243.229 flavor=osic-baremetal-comp
compute-3 ansible_ssh_user=ubuntu ansible_ssh_host=172.30.244.31 flavor=osic-baremetal-comp
compute-4 ansible_ssh_user=ubuntu ansible_ssh_host=172.30.244.29 flavor=osic-baremetal-comp
compute-5 ansible_ssh_user=ubuntu ansible_ssh_host=172.30.243.234 flavor=osic-baremetal-comp
compute-6 ansible_ssh_user=ubuntu ansible_ssh_host=172.30.243.232 flavor=osic-baremetal-comp
compute-7 ansible_ssh_user=ubuntu ansible_ssh_host=172.30.243.233 flavor=osic-baremetal-comp
compute-8 ansible_ssh_user=ubuntu ansible_ssh_host=172.30.243.235 flavor=osic-baremetal-comp
compute-9 ansible_ssh_user=ubuntu ansible_ssh_host=172.30.243.236 flavor=osic-baremetal-comp


[compute]

compute-1 ansible_ssh_user=ubuntu ansible_ssh_host=172.30.243.228 flavor=osic-baremetal-comp
compute-2 ansible_ssh_user=ubuntu ansible_ssh_host=172.30.243.229 flavor=osic-baremetal-comp
compute-3 ansible_ssh_user=ubuntu ansible_ssh_host=172.30.244.31 flavor=osic-baremetal-comp
compute-4 ansible_ssh_user=ubuntu ansible_ssh_host=172.30.244.29 flavor=osic-baremetal-comp
compute-5 ansible_ssh_user=ubuntu ansible_ssh_host=172.30.243.234 flavor=osic-baremetal-comp
compute-6 ansible_ssh_user=ubuntu ansible_ssh_host=172.30.243.232 flavor=osic-baremetal-comp
compute-7 ansible_ssh_user=ubuntu ansible_ssh_host=172.30.243.233 flavor=osic-baremetal-comp
compute-8 ansible_ssh_user=ubuntu ansible_ssh_host=172.30.243.235 flavor=osic-baremetal-comp
compute-9 ansible_ssh_user=ubuntu ansible_ssh_host=172.30.243.236 flavor=osic-baremetal-comp

[logging]

logger-1 ansible_ssh_user=ubuntu ansible_ssh_host=172.30.243.237 flavor=osic-baremetal-comp


[network]

network-1 ansible_ssh_user=ubuntu ansible_ssh_host=172.30.243.215 flavor=osic-baremetal-comp
network-2 ansible_ssh_user=ubuntu ansible_ssh_host=172.30.243.238 flavor=osic-baremetal-comp


[swift]

swift-1 ansible_ssh_user=ubuntu ansible_ssh_host=172.30.243.216 flavor=osic-baremetal-object
swift-2 ansible_ssh_user=ubuntu ansible_ssh_host=172.30.243.217 flavor=osic-baremetal-object
swift-3 ansible_ssh_user=ubuntu ansible_ssh_host=172.30.243.218 flavor=osic-baremetal-object


[cinder]

cinder-1 ansible_ssh_user=ubuntu ansible_ssh_host=172.30.243.220 flavor=osic-baremetal-block
cinder-2 ansible_ssh_user=ubuntu ansible_ssh_host=172.30.243.219 flavor=osic-baremetal-block
cinder-3 ansible_ssh_user=ubuntu ansible_ssh_host=172.30.243.221 flavor=osic-baremetal-block
```



### Test connectivity to the target hosts

```

apt-get update; apt-get install python-pip
apt-get update
apt-get install python-pip build-essential python-dev
pip install ansible

cat /root/.ssh/id_rsa.pub >> /home/ubuntu/.ssh/authorized_keys

vi /etc/ansible/ansible.cfg
...
[defaults]
...
host_key_checking = False
...

[ssh_connection]
ssh_args = -o ControlMaster=no -o ControlPath=/tmp/ansible-ssh-%h-%p-%r -o CheckHostIP=no -o ConnectTimeout=4000
pipelining=True
...


ansible -i inventory/hosts all -m shell -a 'uptime' -f 30

```


### Set up the networking config file

This is a python script that creates 172.X.X.X/20 networks of the same size as the onmetal network. This way each 
onmetal can have the same offset and last octet as its onmetal ip to keep things easier to track.  The playbooks
and templates will handle the actual configuration. The vxlan id's and the multicast group are randomly selected
to prevent collisions from other projects.

```
scripts/gen-onironic-nets.py -o vars/incsc_network_config.yml

cat vars/incsc_network_config.yml

vxlan_group: 239.51.50.226

mgmt_vxlan: 2877284
mgmt_network: 172.22.0.0/20
mgmt_netmask: 255.255.240.0

storage_vxlan: 2877285
storage_network: 172.22.16.0/20
storage_netmask: 255.255.240.0

flat_vxlan: 2877286
flat_network: 172.22.32.0/20
flat_netmask: 255.255.240.0

vlan_vxlan: 2877287
vlan_network: 172.22.48.0/20
vlan_netmask: 255.255.240.0

tunnel_vxlan: 2877288
tunnel_network: 172.22.64.0/20
tunnel_netmask: 255.255.240.0

repl_vxlan: 2877289
repl_network: 172.22.80.0/20
repl_netmask: 255.255.240.0

```


### Prepare the hosts

The prep-onironic-boxes will do some baseline actions and set up networking based on the config just created. During the
networking setup, all devices will be rebooted.  It saves the deployment box for last, so you will be kicked off on the last
play.

```
ansible-playbook -i inventory/hosts prep-onironic-boxes.yml -e vars/incsc_network_config.yml -f 30 --list-hosts
ansible-playbook -i inventory/hosts prep-onironic-boxes.yml -e vars/incsc_network_config.yml -f 30 

```


### Prepare the disks

The disks differ by flavor.  All have a large disk for the lxc container and/or vm creation space. The object related flavor has 
several large disks set up in a single disk raid 0 for each. The block related flavor has a single large raid disk used for the
cinder-volumes lvm volume.   You can see the default configs in the ansible role for the disk config.

```
cat roles/osic-onironic-diskconf/vars/main.yml
---

# Disks used in all non-storage devices(flavor osic-baremetal-comp)
non_storage_lxc_disk: "sdc"

# Disks used in swift/ceph devices(flavor osic-baremetal-object)
object_disks:
  - "sdb"
  - "sdc"
  - "sdd"
  - "sde"
  - "sdf"
  - "sdg"
  - "sdh"
  - "sdi"
  - "sdj"
  - "sdk"


# Disks used in cinder devices(flavor osic-baremetal-block)
block_lxc_disk: "sdb"

block_volumes_disk: "sdc"
```

The following playbook confingures the disks based on the flavor variable and inventory role.

```
ansible-playbook -i inventory/hosts prep-onironic-disks.yml -e vars/incsc_network_config.yml -f 30 --list-hosts
ansible-playbook -i inventory/hosts prep-onironic-disks.yml -e vars/incsc_network_config.yml -f 30 
```






## Configuring the openstack environment

These steps are using an earlier version of the networking config.  We need to updates these docs on the next build
to include the newer networing configuration.  It would also be nice to script this out via some playbooks and templates.

Following steps from: https://github.com/osic/ref-impl/blob/master/documents/osa-refimpl-deploy.md


```
git clone -b stable/mitaka https://github.com/openstack/openstack-ansible.git /opt/openstack-ansible
git checkout stable/newton
git describe --abbrev=0 --tags
git checkout 14.0.2

cd /opt/openstack-ansible
scripts/bootstrap-ansible.sh
cd /opt/openstack-ansible/playbooks/

cp -rf /opt/ref-impl/openstack_deploy /etc/
```


```
vi /etc/openstack_deploy/openstack_user_config.yml
```

```
---
cat /etc/openstack_deploy/openstack_user_config.yml 
---
#ironic_net: 172.30.240.0/20
#vxlan_group: 239.51.50.73
#management_vxlan: 4611189
#management_network: 172.22.0.0/22
#storage_vxlan: 4611193
#storage_network: 172.22.4.0/22
#overlay_vxlan: 4611197
#overlay_network: 172.22.8.0/22
#flat_vxlan: 4611201
#flat_network: 172.22.12.0/22


cidr_networks:
  container: 172.22.0.0/22
  tunnel: 172.22.8.0/22
  storage: 172.22.4.0/22

used_ips:
  - "172.22.0.0,172.22.0.254"
  - "172.22.4.0,172.22.4.254"
  - "172.22.8.0,172.22.8.254"
  - "172.22.12.0,172.22.12.254"

global_overrides:
  internal_lb_vip_address: "172.22.0.213"
  external_lb_vip_address: "172.22.12.213"
  tunnel_bridge: "br-vxlan"
  management_bridge: "br-mgmt"
  provider_networks:
    - network:
        container_bridge: "br-mgmt"
        container_type: "veth"
        container_interface: "eth1"
        ip_from_q: "container"
        type: "raw"
        group_binds:
          - all_containers
          - hosts
        is_container_address: true
        is_ssh_address: true
    - network:
        container_bridge: "br-vxlan"
        container_type: "veth"
        container_interface: "eth10"
        ##container_mtu: "9000"
        ip_from_q: "tunnel"
        type: "vxlan"
        range: "1:1000"
        net_name: "vxlan"
        group_binds:
          - neutron_linuxbridge_agent
    - network:
        container_bridge: "br-flat"
        container_type: "veth"
        container_interface: "eth12"
        type: "flat"
        net_name: "flat"
        group_binds:
          - neutron_linuxbridge_agent
    - network:
        container_bridge: "br-vlan"
        container_type: "veth"
        container_interface: "eth11"
        type: "vlan"
        range: "839:849"
        net_name: "vlan"
        group_binds:
          - neutron_linuxbridge_agent
    - network:
        container_bridge: "br-storage"
        container_type: "veth"
        container_interface: "eth2"
        ##container_mtu: "9000"
        ip_from_q: "storage"
        type: "raw"
        group_binds:
          - glance_api
          - cinder_api
          - cinder_volume
          - nova_compute
          # Uncomment the next line if using swift with a storage network.
          #- swift_proxy

```




```
vi /etc/openstack_deploy/conf.d/compute.yml
```

```
---
compute_hosts:
  compute-1:
    ip: 172.22.0.228
  compute-2:
    ip: 172.22.0.229
  compute-3:
    ip: 172.22.0.230
  compute-4:
    ip: 172.22.0.231
  compute-5:
    ip: 172.22.0.234
  compute-6:
    ip: 172.22.0.232
  compute-7:
    ip: 172.22.0.233
  compute-8:
    ip: 172.22.0.235
  compute-9:
    ip: 172.22.0.236
```


```
vi /etc/openstack_deploy/conf.d/infra.yml
```

```
---
shared-infra_hosts:
  infra-1:
    ip: 172.22.0.213
  infra-2:
    ip: 172.22.0.210
  infra-3:
    ip: 172.22.0.212

os-infra_hosts:
  infra-1:
    ip: 172.22.0.213
  infra-2:
    ip: 172.22.0.210
  infra-3:
    ip: 172.22.0.212

storage-infra_hosts:
  infra-1:
    ip: 172.22.0.213
  infra-2:
    ip: 172.22.0.210
  infra-3:
    ip: 172.22.0.212

repo-infra_hosts:
  infra-1:
    ip: 172.22.0.213
  infra-2:
    ip: 172.22.0.210
  infra-3:
    ip: 172.22.0.212

identity_hosts:
  infra-1:
    ip: 172.22.0.213
  infra-2:
    ip: 172.22.0.210
  infra-3:
    ip: 172.22.0.212

```




```
vi /etc/openstack_deploy/conf.d/loadbalancer.yml
```

```
---
haproxy_hosts:
  infra-1:
    ip: 172.22.0.213
```





```
 vi /etc/openstack_deploy/conf.d/logging.yml 
```

```
---
log_hosts:
  logger-1:
    ip: 172.22.0.237
```



```
vi /etc/openstack_deploy/conf.d/network.yml 
```

```
---
network_hosts:
  network-1:
    ip: 172.22.0.215
  network-2:
    ip: 172.22.0.238
```


```
vi /etc/openstack_deploy/conf.d/storage.yml 
```

```
storage_hosts:
  cinder-1:
    ip: 172.22.0.220
    container_vars:
      cinder_storage_availability_zone: cinderAZ_1
      cinder_default_availability_zone: cinderAZ_1
      cinder_backends:
        lvm:
          volume_backend_name: LVM_iSCSI
          volume_driver: cinder.volume.drivers.lvm.LVMVolumeDriver
          volume_group: cinder-volumes
          iscsi_ip_address: 172.22.4.220 
        limit_container_types: cinder_volume
  cinder-2:
    ip: 172.22.0.219
    container_vars:
      cinder_storage_availability_zone: cinderAZ_1
      cinder_default_availability_zone: cinderAZ_1
      cinder_backends:
        lvm:
          volume_backend_name: LVM_iSCSI
          volume_driver: cinder.volume.drivers.lvm.LVMVolumeDriver
          volume_group: cinder-volumes
          iscsi_ip_address: 172.22.4.219
        limit_container_types: cinder_volume
  cinder-3:
    ip: 172.22.0.221
    container_vars:
      cinder_storage_availability_zone: cinderAZ_1
      cinder_default_availability_zone: cinderAZ_1
      cinder_backends:
        lvm:
          volume_backend_name: LVM_iSCSI
          volume_driver: cinder.volume.drivers.lvm.LVMVolumeDriver
          volume_group: cinder-volumes
          iscsi_ip_address: 172.22.4.221
        limit_container_types: cinder_volume
```



```
vi /etc/openstack_deploy/conf.d/swift.yml 
```

```
global_overrides:
  swift:
    part_power: 8
    storage_network: 'br-storage'
    replication_network: 'br-storage'
    drives:
      - name: sdb
      - name: sdc
      - name: sdd
      - name: sde
      - name: sdf
      - name: sdg
      - name: sdh
      - name: sdi
      - name: sdj
      - name: sdk
    mount_point: /srv/node
    storage_policies:
      - policy:
          name: default
          index: 0
          default: True

swift-proxy_hosts:
  infra-1:
    ip: 172.22.0.213
    container_vars:
      swift_proxy_vars:
        read_affinity: "r1=100"
        write_affinity: "r1"
        write_affinity_node_count: "2 * replicas"
  infra-2:
    ip: 172.22.0.210
    container_vars:
      swift_proxy_vars:
        read_affinity: "r2=100"
        write_affinity: "r2"
        write_affinity_node_count: "2 * replicas"
  infra-3:
    ip: 172.22.0.212
    container_vars:
      swift_proxy_vars:
        read_affinity: "r3=100"
        write_affinity: "r3"
        write_affinity_node_count: "2 * replicas"

swift_hosts:
  swift-1:
    ip: 172.22.0.216
    container_vars:
      swift_vars:
        limit_container_types: swift
        zone: 0
        region: 1
  swift-2:
    ip: 172.22.0.217
    container_vars:
      swift_vars:
        limit_container_types: swift
        zone: 0
        region: 1
  swift-3:
    ip: 172.22.0.218
    container_vars:
      swift_vars:
        limit_container_types: swift
        zone: 0
        region: 1

```



## generate the passwords

```
cd /opt/openstack-ansible/scripts
python pw-token-gen.py --file /etc/openstack_deploy/user_secrets.yml
```


## run openstack scripts


```
apt-get install python-netaddr

tmux new -s osa_build
cd /opt/openstack-ansible/playbooks

openstack-ansible setup-hosts.yml --list-hosts

export ANSIBLE_FORCE_COLOR=true; stdbuf -o0 -e0 -i0 openstack-ansible setup-hosts.yml -f 30 | tee hostsetup.log

export ANSIBLE_FORCE_COLOR=true; stdbuf -o0 -e0 -i0 openstack-ansible setup-infrastructure.yml -f 30 | tee infsetup.log

export ANSIBLE_FORCE_COLOR=true; stdbuf -o0 -e0 -i0 openstack-ansible setup-openstack.yml -f 30 | tee openstacksetup.log

```






## Outbound connectivity

We are using the 'flat' network for external(publicnet) gateway networks. In order to connect externally, you need to set up the .1 ip on a box connected to the network(deploy or infra-1) and set up a nat entry.
```
iptables -t nat -A POSTROUTING -s 172.22.12.0/22 ! -d 172.22.12.0/22 -o br-control -j MASQUERADE


# These two may not be needed.
iptables -A FORWARD -i br-flat -o br-control -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i br-control -o br-flat -j ACCEPT


# Save it
apt-get install iptables-persistent  (answer 'yes' to save the current settings)


ip addr add 172.22.12.1/22 dev br-flat

vi /etc/network/interfaces

# extra ip for external network access for the 'flat' network

auto br-control
iface br-control inet static
    bridge_ports bond0
    bridge_fd 9
    bridge_hello 2
    bridge_maxage 12
    bridge_stp off
    address 172.30.243.128
    netmask 255.255.252.0
    gateway 172.30.240.1
    dns-nameservers 8.8.8.8 8.8.4.4
    up ip addr add 172.22.12.1/22 dev br-flat
    down ip addr del 172.22.12.1/22 dev br-flat

```





## Adding hosts

```
cd /opt/openstack-ansible/playbooks
openstack-ansible setup-hosts.yml --limit NEW_HOST_NAME
openstack-ansible setup-openstack.yml --skip-tags nova-key-distribute --limit NEW_HOST_NAME
openstack-ansible setup-openstack.yml --tags nova-key --limit compute_hosts
```



# If needing to re-deploy

```

ansible -i ./inventory/hosts 'all:!deploy' -m shell -a 'rm -rf /root/.pip; rm -f /etc/apt/apt.conf.d/00apt-cacher-proxy; rm -f /var/lib/lxc/LXC_NAME/rootfs/etc/apt/apt.conf.d/00apt-cacher-proxy'

```




# rabbitmq monitoring
rabbitmqctl add_user monitoring openstack
rabbitmqctl set_permissions -p / monitoring ".*" ".*" ".*"
rabbitmqctl change_password monitoring openstack


# salt setup...
