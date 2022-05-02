#!/bin/sh
# debug ping
# we found that a dns lookup involving /etc/nsswitch.conf and /etc/resolv.conf
strace -e trace=openat -f ping -c1 baidu.com

# debug host
# we found that a host lookup involving /etc/resolv.conf
strace -e trace=openat -f host baidu.com
