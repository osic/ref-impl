=========================
Bootstrapping the servers
=========================

When all servers finish PXE booting, bootstrap the servers.

Generate Ansible inventory
~~~~~~~~~~~~~~~~~~~~~~~~~~

#. Run the ``generate_ansible_hosts.py`` Python script:

   .. code:: console

      cd /root/rpc-prep-scripts

      python generate_ansible_hosts.py /root/input.csv > /root/osic-prep-ansible/hosts

#. (Optional) If this will be an OpenStack-Ansible installation, organize the
   Ansible hosts file into groups for controller, logging, compute, cinder, and
   swift:

   An example OpenStack-Ansible installation:

   .. code::

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

The LXC container does not have all of the new server's SSH fingerprints
in the ``known_hosts`` file. This is needed to bypass prompts and
create a silent login when SSHing to servers.

#. Add the SSH fingerprints to``known_hosts`` by running the following
   command:

   .. code::

      for i in $(cat /root/osic-prep-ansible/hosts | awk /ansible_ssh_host/ | cut -d'=' -f2)
      do
      ssh-keygen -R $i
      ssh-keyscan -H $i >> /root/.ssh/known_hosts
      done

#. Verify Ansible can talk to every server. Your password is `cobbler`:

   .. code:: console

      cd /root/osic-prep-ansible

      ansible -i hosts all -m shell -a "uptime" --ask-pass

Setup SSH public keys
~~~~~~~~~~~~~~~~~~~~~

#. Generate an SSH key pair for the LXC container:

   .. code:: console

      ssh-keygen

#. Copy the LXC container's SSH public key to the ``osic-prep-ansible``
   directory:

   .. code:: console

      cp /root/.ssh/id_rsa.pub /root/osic-prep-ansible/playbooks/files/public_keys/osic-prep

Bootstrap the servers
~~~~~~~~~~~~~~~~~~~~~

#. Run the ``bootstrap.yml`` Ansible Playbook. Your password is `cobbler`:

   .. code:: console

      cd /root/osic-prep-ansible

      ansible-playbook -i hosts playbooks/bootstrap.yml --ask-pass

Clean up LVM logical volumes
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

(Optional) If this will be an OpenStack-Ansible installation, you will need to
clean up particular LVM Logical Volumes.
Each server is provisioned with a standard set of LVM Logical Volumes.
Not all servers need all of the LVM Logical Volumes. Clean them up with
the following steps.

#. Remove LVM logical volume ``nova00`` from the controller, logging,
   cinder, and swift nodes:

   .. code::

      ansible-playbook -i hosts playbooks/remove-lvs-nova00.yml

#. Remove LVM Logical Volume ``deleteme00`` from all nodes:

   .. code::

      ansible-playbook -i hosts playbooks/remove-lvs-deleteme00.yml

Update Linux kernel
~~~~~~~~~~~~~~~~~~~

Every server in the OSIC RAX cluster is running two Intel X710 10 GbE
NICs.

.. important::
   
   These NICs have not been well tested in Ubuntu and as such the
   upstream i40e driver in the default 14.04.3 Linux kernel will begin
   showing issues when you setup VLAN tagged interfaces and bridges.

To get around this, install an updated Linux kernel by running the
following commands:

.. code:: console

   cd /root/osic-prep-ansible

   ansible -i hosts all -m shell -a "apt-get update; apt-get install -y linux-generic-lts-xenial" --forks 25

Reboot nodes
~~~~~~~~~~~~

Reboot all servers:

.. code::

   ansible -i hosts all -m shell -a "reboot" --forks 25

Once all servers reboot, you can begin installing
`OpenStack-Ansible <http://docs.openstack.org/developer/openstack-ansible/install-guide/index.html>`_.