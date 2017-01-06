## Overview

We need various disk configs based on the role and flavor. This role handles the configuration for each of those.

The role does the following for trusty, xenial and centos7

  - for non-storage devices, set up a large lxc lvm volume group(using sdc) and set up a 72G openstack00 volume mounted under /openstack
  - for compute devices, create a nova00 volume consisting of the remaining lxc volume group(around 2T) and mount under /var/lib/nova
  - for swift(object flavor) devices, create an empty openstack dir. Also for each sdb -> sdk device, partition, format as xfs, mount
    under /srv/node/sdX and set up in the /etc/fstab.
  - for cinder(block flavor) devices, set up the lxc volume and openstack00 mount as we did with the non-storage devices(using sdb).  Also
    create a cinder-volumes lvm volume group using the large raid 10 sdc device.

## Required External Input Variables

None


## Default Variables under ./vars that can be overridden

  - **non_storage_lxc_disk:** The default disk on osic-onmetal-comp devices(sdc) to use for the 'lxc' volume group.
  - **object_disks:** disks set up in a raid 0 and used for either swift or ceph. Runs from sdb to sdk on the osic-onmetal-object
                    flavors
  - **block_lxc_disk:**  Disk to use for the lxc container on block devices.(sdb) on the osic-onmetal-block flavors.
  - **block_volumes_disk:** Large raid 10 to use for cinder-volumes(sdc) on the osic-onmetal-block flavors.



## Usage Example


  - Example **configdisk.yml** playbook Content

```
---

- name: Prepare ironic hosts disks with flavor 'osic-baremetal-comp' in non-storage devices
  hosts: 'all:!cinder:!swift:!ceph'
  become: yes
  become_user: root
  roles:
    - { role: osic-onironic-diskconf, disk_action: 'non-storage-disk-setup' }

- name: Prepare ironic hosts disks with flavor 'osic-baremetal-comp' in the compute group
  hosts: 'compute'
  become: yes
  become_user: root
  roles:
    - { role: osic-onironic-diskconf, disk_action: 'compute-disk-setup' }

- name: Prepare ironic host disks with flavor 'osic-baremetal-block' and under the 'cinder' group
  hosts: 'cinder'
  become: yes
  become_user: root
  roles:
    - { role: osic-onironic-diskconf, disk_action: 'cinder-disk-setup' }

- name: Prepare ironic host disks with flavor 'osic-baremetal-object' and under the 'swift' group
  hosts: 'swift'
  become: yes
  become_user: root
  roles:
    - { role: osic-onironic-diskconf, disk_action: 'swift-disk-setup' }


```


- Example ansible run

```
ansible-playbook -i inventory/hosts configdisk.yml
```

## Results 


  - All devices(except for swift) create an lxc volume group from the avail 2T disk.
  - All devices have an /openstack directory(for all but swift device, create a 72G volume in the lxc volume group.)
  - Compute devices have a large /var/lib/nova mount set up for VM storage.
  - Swift devices ahve several large disks formated as xfs and mounted under /srv/node/<devicename> for swift usage.
  - Cinder has a large cinder-volumes lvm volume group available for block storage use.
