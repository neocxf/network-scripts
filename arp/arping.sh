#!/bin/sh

# clean all the arp cache
ip -s -s neigh flush all

nmap -sP 192.168.1.0/24

 