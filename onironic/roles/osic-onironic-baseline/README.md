## Overview

Does the following for trusty, xenial and centos7

  - sets up local hosts file on the deploy box
  - sets up ssh root access
  - sets up apt or yum configs
  - installs needed dpkg or rpm packages including the hp utilities 
  - configures networking kernel modules
  - updates the kernel  
  - reboots the kernel updated systems and waits for them to come back online


## Required External Input Variables

None


## Default Variables under ./vars that can be overridden

  - **hosts_line:** placemark var to be used later in the playbook
  - **sshservice:** defaults to 'ssh' and is changed in the tasks to 'sshd' for centos systems.
  - **repos:** {trusty: [...], xenial: [...]}: arrays with a list of apt sources to use for the apt config.
  - **hpkeys:** list of hp repo keys to import 
  - **apt_packages:** list of dpkg packages to install via apt
  - **yum_packages:** list of rpm packages to install via yum


## Usage Example


  - Example runbaseline.yml playbook Content

```
---
- name: Run some general baseline configs
  hosts: 'all'
  remote_user: root
  become: yes
  gather_facts: true
  roles:
    - osic-onironic-baseline
```


- Example ansible run

```
ansible-playbook -i inventory/hosts runbaseline.yml
```

## Results 

prepares the systems for the openstack-ansible install (minus any disk or network changes)

