#!/bin/bash

sudo ip netns del netns_dustin  >/dev/null 2>&1 || true
sudo ip netns del netns_leah >/dev/null 2>&1 || true

sudo iptables -t nat -F POSTROUTING >/dev/null 2>&1 || true
sudo iptables -t filter -F FORWARD  >/dev/null 2>&1 || true

# stop the dynamic routes created by bird
sudo systemctl stop bird >/dev/null 2>&1 || true