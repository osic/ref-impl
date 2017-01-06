## Overview

We have to use vxlan interfaces for openstack in the onmetal environment as we do not have available vlan trunking set up.
As a workaround, we are using bridges tied to vxlan interfaces which are in turn tied to the main bond0 bridge(br-control).

The role does the following for trusty, xenial and centos7

  - uses pre-defined variables to decide which networks, multicast group and vxlan ids to use for the following networks:  
        'mgmt', 'storage', 'flat', 'vlan', 'tunnel' and 'repl'
  - increments the 3rd octet to match the main ironic network offset to use as the same offset for each network interface.
  - sets the last octet as the ironic network last octet for each network interface.
  - Configures a vxlan interface <netid>-mesh and a related bridge br-<netid> interface to use for openstack.
  - For debian it configures /etc/network/interfaces and individual vxlan files under /etc/network/mesh-interfaces.d
  - For redhat, it configures /etc/network/ifcfg-bond0 and ifcfg-br-<netid> bridge interfaces.  It also sets up 
    /etc/resolv.conf and /sbin/ifup-local & /sbin/ifdown-local for vxlan interfaces.
  - The non-deploy servers are rebooted and waited on.
  - The deploy server is rebooted(will be kicked out as you will be running this on the deploy server.


## Required External Input Variables

In the **ref-impl/onironic** directory a **scripts/gen-onironic-nets.py** python script is used to automatically generate the
variables.

  - **vxlan_group: 239.51.X.X** multicast group to use for the vxlans
  - **mgmt_vxlan: XXXXXXX1**              vxlan id to use for this network. Its randomly generaged and increased by 1 for each network.
  - **mgmt_network: 172.22.0.0/20**       network to use for management.  
  - **mgmt_netmask: 255.255.240.0**       mask to use for the management network.
  - **storage_vxlan: XXXXXXX2**           the storage entries are the same as above, but used for swift, ceph and cinder.
  - **storage_network: 172.22.16.0/20**
  - **storage_netmask: 255.255.240.0**
  - **flat_vxlan: XXXXXXX3**              same as above, but used if a flat network is needed.
  - **flat_network: 172.22.32.0/20**
  - **flat_netmask: 255.255.240.0**
  - **vlan_vxlan: XXXXXXX4**              same as above, but used if vlans are needed.
  - **vlan_network: 172.22.48.0/20**
  - **vlan_netmask: 255.255.240.0**
  - **tunnel_vxlan: XXXXXXX5**            same as above, but used for customer defined networks.
  - **tunnel_network: 172.22.64.0/20**
  - **tunnel_netmask: 255.255.240.0**
  - **repl_vxlan: XXXXXXX6**              same as above, but used for replication if needed
  - **repl_network: 172.22.80.0/20**
  - **repl_netmask: 255.255.240.0**




## Default Variables under ./vars that can be overridden

  - **dns1:** dns server 1 used in the network configurations
  - **dns2:** dns server 2 used in the network configurations
  - **needs_reboot:** set to false by default.  used to track changes to see if a reboot is needed later on.


## Usage Example


  - Example **confignetwork.yml** playbook Content

```
---
  hosts: 'all'
  remote_user: root
  become: yes
  gather_facts: true
  roles:
    - osic-onironic-netconf
```


- Example ansible run

```
gen-onironic-nets.py -o vars/mynetworks.yml
ansible-playbook -i inventory/hosts -e @vars/mynetworks.yml confignetwork.yml
```

## Results 

Have a system with multiple <netid>-mesh vxlan interfaces tied to <netid>-mesh vxlan interfaces to separate out 
the various networks needed for openstack.


