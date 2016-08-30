=========================
Bootstrapping the servers
=========================

When all servers finish PXE booting, you will now need to bootstrap the
servers.

Generate Ansible inventory
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

Verify connectivity
~~~~~~~~~~~~~~~~~~~

The LXC container will not have all of the new server's SSH fingerprints
in its **known\_hosts** file. This is needed to bypass prompts and
create a silent login when SSHing to servers. Programatically add them
by running the following command:

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

Setup SSH public keys
~~~~~~~~~~~~~~~~~~~~~

Generate an SSH key pair for the LXC container:

::

    ssh-keygen

Copy the LXC container's SSH public key to the **osic-prep-ansible**
directory:

::

    cp /root/.ssh/id_rsa.pub /root/osic-prep-ansible/playbooks/files/public_keys/osic-prep

Bootstrap the servers
~~~~~~~~~~~~~~~~~~~~~

Finally, run the bootstrap.yml Ansible Playbook (the password is again
**cobbler**):

::

    cd /root/osic-prep-ansible

    ansible-playbook -i hosts playbooks/bootstrap.yml --ask-pass

Clean up LVM logical volumes
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

Update Linux kernel
~~~~~~~~~~~~~~~~~~~

Every server in the OSIC RAX Cluster is running two Intel X710 10 GbE
NICs. These NICs have not been well tested in Ubuntu and as such the
upstream i40e driver in the default 14.04.3 Linux kernel will begin
showing issues when you setup VLAN tagged interfaces and bridges.

In order to get around this, you must install an updated Linux kernel.

You can do this by running the following commands:

::

    cd /root/osic-prep-ansible

    ansible -i hosts all -m shell -a "apt-get update; apt-get install -y linux-generic-lts-xenial" --forks 25

Reboot nodes
~~~~~~~~~~~~

Finally, reboot all servers:

::

    ansible -i hosts all -m shell -a "reboot" --forks 25

Once all servers reboot, you can begin installing openstack-ansible.
