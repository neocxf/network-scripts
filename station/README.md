# Boot up on windows

## Prerequisite

```bash
vagrant plugin install vagrant-winnfsd
vagrant plugin install vagrant-guest_ansible
vagrant plugin install vagrant-guest_ansible
vagrant plugin install vagrant-disksize
```

## using the customized network

```bash
vagrant up
```

## ansible command

```bash
# ad-hoc commands for localhost setup
ansible-galaxy install -r role.yml
ansible-playbook provision.yml  --connection local --inventory 127.0.0.1, --limit 127.0.0.1 --tags vagrant
```

# Refer

1. [virsh cheetsheet](https://computingforgeeks.com/virsh-commands-cheatsheet/)
2. [using kvm libvirt macvtap interfaces](https://blog.scottlowe.org/2016/02/09/using-kvm-libvirt-macvtap-interfaces/)
