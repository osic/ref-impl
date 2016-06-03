# All of this should be executed from the utility container for ease of operation
#  The utility container has been setup with all of the CLI clients installed within
#  the root namespace of the container. If you are NOT in the utility container you
#  will need to work with the various services from within the service virtual environment.
#  All service virtual environments can be found within "/openstack/venvs".


# Net create for our VLAN networks
for net in 839:172.22.136 840:172.22.140 841:172.22.144 842:172.22.148 843:172.22.152 844:172.22.156 845:172.22.160 846:172.22.164 847:172.22.168 848:172.22.172 849:172.22.176; do
    neutron net-create provider-${net%%':'*} \
        --shared \
        --router:external True \
        --provider:physical_network vlan \
        --provider:network_type vlan \
        --provider:segmentation_id ${net%%':'*}
done

# Subnet create for our networks
for net in 839:172.22.136 840:172.22.140 841:172.22.144 842:172.22.148 843:172.22.152 844:172.22.156 845:172.22.160 846:172.22.164 847:172.22.168 848:172.22.172 849:172.22.176; do
    neutron subnet-create provider-${net%%':'*} ${net#*':'}.0/22 \
        --name subnet-provider-${net%%':'*} \
        --gateway ${net#*':'}.1 \
        --allocation-pool start=${net#*':'}.101,end=${net#*':'}.255 \
        --dns-nameservers list=true 8.8.4.4 8.8.8.8
done

# Change the default security group rules to allow for everything. This is optional, if you want your could to
#  be restricted change this to fit your needs.
# Allow ICMP
neutron security-group-rule-create --protocol icmp \
                                   --direction ingress \
                                   default
# Allow all TCP
neutron security-group-rule-create --protocol tcp \
                                   --port-range-min 1 \
                                   --port-range-max 65535 \
                                   --direction ingress \
                                   default
# Allow all UDP
neutron security-group-rule-create --protocol udp \
                                   --port-range-min 1 \
                                   --port-range-max 65535 -\
                                   -direction ingress \
                                   default

# Create some default images
wget http://uec-images.ubuntu.com/releases/14.04/release/ubuntu-14.04-server-cloudimg-amd64-disk1.img
glance image-create --name 'Ubuntu 14.04 LTS' \
                    --container-format bare \
                    --disk-format qcow2 \
                    --visibility public \
                    --progress \
                    --file ubuntu-14.04-server-cloudimg-amd64-disk1.img
rm ubuntu-14.04-server-cloudimg-amd64-disk1.img

wget http://uec-images.ubuntu.com/releases/15.10/release/ubuntu-15.10-server-cloudimg-amd64-disk1.img
glance image-create --name 'Ubuntu 15.10' \
                    --container-format bare \
                    --disk-format qcow2 \
                    --visibility public \
                    --progress \
                    --file ubuntu-15.10-server-cloudimg-amd64-disk1.img
rm ubuntu-15.10-server-cloudimg-amd64-disk1.img

wget http://uec-images.ubuntu.com/releases/16.04/beta-2/ubuntu-16.04-beta2-server-cloudimg-amd64-disk1.img
glance image-create --name 'Ubuntu 16.04 Beta2' \
                    --container-format bare \
                    --disk-format qcow2 \
                    --visibility public \
                    --progress \
                    --file ubuntu-16.04-beta2-server-cloudimg-amd64-disk1.img
rm ubuntu-16.04-beta2-server-cloudimg-amd64-disk1.img

wget https://download.fedoraproject.org/pub/fedora/linux/releases/23/Cloud/x86_64/Images/Fedora-Cloud-Base-23-20151030.x86_64.qcow2
glance image-create --name 'Fedora 23' \
                    --container-format bare \
                    --disk-format qcow2 \
                    --visibility public \
                    --progress \
                    --file Fedora-Cloud-Base-23-20151030.x86_64.qcow2
rm Fedora-Cloud-Base-23-20151030.x86_64.qcow2

wget http://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2
glance image-create --name 'CentOS 7' \
                    --container-format bare \
                    --disk-format qcow2 \
                    --visibility public \
                    --progress \
                    --file CentOS-7-x86_64-GenericCloud.qcow2
rm CentOS-7-x86_64-GenericCloud.qcow2

wget http://download.opensuse.org/repositories/Cloud:/Images:/Leap_42.1/images/openSUSE-Leap-42.1-OpenStack.x86_64-0.0.4-Build2.12.qcow2
glance image-create --name 'OpenSuse Leap 42' \
                    --container-format bare \
                    --disk-format qcow2 \
                    --visibility public \
                    --progress \
                    --file openSUSE-Leap-42.1-OpenStack.x86_64-0.0.4-Build2.12.qcow2
rm openSUSE-Leap-42.1-OpenStack.x86_64-0.0.4-Build2.12.qcow2

wget http://download.opensuse.org/repositories/Cloud:/Images:/openSUSE_13.2/images/openSUSE-13.2-OpenStack-Guest.x86_64.qcow2
glance image-create --name 'OpenSuse 13.2' \
                    --container-format bare \
                    --disk-format qcow2 \
                    --visibility public \
                    --progress \
                    --file openSUSE-13.2-OpenStack-Guest.x86_64.qcow2
rm openSUSE-13.2-OpenStack-Guest.x86_64.qcow2

wget http://cdimage.debian.org/cdimage/openstack/current/debian-8.3.0-openstack-amd64.qcow2
glance image-create --name 'Debian 8.3.0' \
                    --container-format bare \
                    --disk-format qcow2 \
                    --visibility public \
                    --progress \
                    --file debian-8.3.0-openstack-amd64.qcow2
rm debian-8.3.0-openstack-amd64.qcow2

wget http://cdimage.debian.org/cdimage/openstack/testing/debian-testing-openstack-amd64.qcow2
glance image-create --name "Debian TESTING $(date +%m-%d-%y)" \
                    --container-format bare \
                    --disk-format qcow2 \
                    --visibility public \
                    --progress \
                    --file debian-testing-openstack-amd64.qcow2
rm debian-testing-openstack-amd64.qcow2
