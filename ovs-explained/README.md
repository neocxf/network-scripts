# openvswitch

## setup env

```bash
# https://ostechnix.com/install-and-configure-kvm-in-ubuntu-20-04-headless-server/
sudo lscpu | grep Virtualization

sudo apt install qemu qemu-kvm libvirt-clients libvirt-daemon-system virtinst bridge-utils


sudo systemctl enable libvirtd
sudo systemctl start libvirtd
sudo systemctl status libvirtd

# disable apparmor
# https://linuxconfig.org/how-to-disable-apparmor-on-ubuntu-20-04-focal-fossa-linux
sudo systemctl disable apparmor

# we must reboot the system to make the apparmor disabled take effect
reboot

vagrant plugin install vagrant-libvirt

# if the above step failed, run this command
sudo apt-get install libxslt-dev libxml2-dev libvirt-dev zlib1g-dev ruby-dev

# after the success install, we can check the json file
cat /usr/share/vagrant-plugins/plugins.d/vagrant-libvirt.json

vagrant plugin install vagrant-mutate

```

## start the vm

```bash
# https://www.rubydoc.info/gems/vagrant-libvirt/0.2.1#possible-problems-with-plugin-installation-on-linux

vagrant up

# make sure the vms up
virsh list

# verify using the virt-manager
sudo apt install virt-manager
# add current user to libvirt to avoid the sudo pass
sudo usermod -a -G libvirt $(whoami)

```

## some basic concepts

1. ![forged transmits](https://i0.wp.com/wahlnetwork.com/wp-content/uploads/2013/04/virtual-vm-mac.png)
2. ![nest vm virtualization](https://storpool.com/wp-content/uploads/2019/11/pasted-image-0.png)

## refer

1. [How The VMware Forged Transmits Security Policy Works](https://wahlnetwork.com/2013/04/29/how-the-vmware-forged-transmits-security-policy-works/)
