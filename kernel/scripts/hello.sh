#!/bin/bash


cd _install
mkdir tmp proc sys etc dev
mkdir -p etc/init.d

cat > etc/fstab <<__EOF__
proc    /proc   proc    defaults        0       0
tmpfs   /tmp    tmpfs   defaults        0       0
sysfs   /sys    sysfs   defaults        0       0
__EOF__


cat > etc/inittab <<__EOF__
::sysinit:/etc/init.d/rcS
::respawn:-/bin/sh
::askfirst:-/bin/sh
::ctrlaltdel:/bin/umount -a -r
__EOF__

cat > etc/init.d/rcS <<__EOF__
#!/bin/bash
echo -e "Welcome to neoLinux"
/bin/mount -a
echo -e "Remounting the root filesystem"
mount -o remount,rw /
mkdir -p /dev/pts
mount -t devpts devpts /dev/pts
echo /sbin/mdev > /proc/sys/kernel/hotplug
mdev -s
__EOF__

cd dev/
mknod console c 5 1
mknod null c 1 3
mknod tty1 c 4 1

cat > mkfs.sh <<__EOF__
#!/bin/bash

rm -rf rootfs.ext3
rm -rf fs

dd if=/dev/zero of=./rootfs.ext3 bs=1M count=32
mkfs.ext3 rootfs.ext3
mkdir fs
mount -o loop rootfs.ext3 ./fs
cp -rf ./_install/* ./fs
umount ./fs
gzip --best -c rootfs.ext3 > rootfs.img.gz
__EOF__


cat startup.sh <<__EOF__
qemu-system-x86_64 -kernel ./linux-4.9.299/arch/x86_64/boot/bzImage -initrd ./busybox-1.35.0/rootfs.img.gz -append 'root=/dev/ram init=/linuxrc' -serial file:output.txt
__EOF__

# debug script to check the boot log
# qemu-system-x86_64 -nographic -kernel ./linux-4.9.299/arch/x86_64/boot/bzImage -initrd ./busybox-1.35.0/rootfs.img.gz -m 512M -append console=ttyS0
