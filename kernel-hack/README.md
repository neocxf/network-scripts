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

## build sourceweb

```bash
wget https://releases.llvm.org/4.0.0/llvm-4.0.0.src.tar.xz
# patch llvm
# https://bugzilla.redhat.com/attachment.cgi?id=1389687&action=diff

cd llvm-4.0.0.src/
mkdir build && cd $_
cmake ../
cmake --build .
sudo cmake --build . --target install


wget https://releases.llvm.org/4.0.0/cfe-4.0.0.src.tar.xz
# patch clang
wget https://git.xirion.net/0x76/nixpkgs/src/commit/129fbd75501785f4e3308d6160590ba465964c5f/pkgs/development/compilers/llvm/4/clang/0001-Fix-compilation-w-gcc9.patch

mkdir build && cd $_
cmake ../
cmake --build .
sudo cmake --build . --target install

sudo apt-get install qt5-make qtbase5-dev
git clone  https://github.com/rprichard/CxxCodeBrowser.git
cd CxxCodeBrowser
mdkir build && cd $_
../configure  --with-clang-dir /usr/local
make -j 4
sudo make install
```

# Refer

1. [virsh cheetsheet](https://computingforgeeks.com/virsh-commands-cheatsheet/)
2. [using kvm libvirt macvtap interfaces](https://blog.scottlowe.org/2016/02/09/using-kvm-libvirt-macvtap-interfaces/)
