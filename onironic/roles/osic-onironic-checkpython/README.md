## Overview

By default Ubuntu 16.04 has python3 installed without a 'python' binary.  Ansible needs it to
run plays. This role checks availability with the ping module and installs python 2 using the
ansible 'raw' module'


## Required External Input Variables

None


## Default Variables under ./vars that can be overridden

None


## Usage Example


  - Example checkpython.yml playbook Content

```
---
- name: The xenial images do not have python installed. Set it up if needed.
  hosts: 'all'
  remote_user: root
  become: yes
  gather_facts: false
  roles:
    - osic-onironic-checkpython
```


- Example ansible run

```
ansible-playbook -i inventory/hosts checkpython.yml
```

## Results 

python2 is installed on any xenial OS and ansible runs work properly.
