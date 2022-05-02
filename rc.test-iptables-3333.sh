#!/bin/bash
#
# rc.test-iptables - test script for iptables chains and tables.
#
# Copyright (C) 2001  Oskar Andreasson &lt;bluefluxATkoffeinDOTnet&gt;
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program or from the site that you downloaded it
# from; if not, write to the Free Software Foundation, Inc., 59 Temple
# Place, Suite 330, Boston, MA  02111-1307   USA
#

#
# Filter table, all chains
#
iptables -t filter -A INPUT  -p tcp --dport 3333 \
-j LOG --log-prefix="filter INPUT[0]:"
iptables -t filter -A INPUT  -p tcp --sport 3333 \
-j LOG --log-prefix="filter INPUT[1]:"
iptables -t filter -A OUTPUT  -p tcp --dport 3333 \
-j LOG --log-prefix="filter OUTPUT[0]:"
iptables -t filter -A OUTPUT  -p tcp --sport 3333 \
-j LOG --log-prefix="filter OUTPUT[1]:"
iptables -t filter -A FORWARD  -p tcp --dport 3333 \
-j LOG --log-prefix="filter FORWARD[0]:"
iptables -t filter -A FORWARD  -p tcp --sport 3333 \
-j LOG --log-prefix="filter FORWARD[1]:"

#
# NAT table, all chains except OUTPUT which don't work.
#
iptables -t nat -A PREROUTING -p tcp --dport 3333 \
-j LOG --log-prefix="nat PREROUTING[0]:"
iptables -t nat -A PREROUTING -p tcp --sport 3333 \
-j LOG --log-prefix="nat PREROUTING[1]:"
iptables -t nat -A POSTROUTING -p tcp --dport 3333 \
-j LOG --log-prefix="nat POSTROUTING[0]:"
iptables -t nat -A POSTROUTING -p tcp --sport 3333 \
-j LOG --log-prefix="nat POSTROUTING[1]:"
iptables -t nat -A OUTPUT -p tcp --dport 3333 \
-j LOG --log-prefix="nat OUTPUT[0]:"
iptables -t nat -A OUTPUT -p tcp --sport 3333 \
-j LOG --log-prefix="nat OUTPUT[1]:"

#
# Mangle table, all chains
#
iptables -t mangle -A PREROUTING  -p tcp --dport 3333 \
-j LOG --log-prefix="mangle PREROUTING[0]:"
iptables -t mangle -A PREROUTING  -p tcp --sport 3333 \
-j LOG --log-prefix="mangle PREROUTING[1]:"
iptables -t mangle -I FORWARD 1  -p tcp --dport 3333 \
-j LOG --log-prefix="mangle FORWARD[0]:"
iptables -t mangle -I FORWARD 1  -p tcp --sport 3333 \
-j LOG --log-prefix="mangle FORWARD[1]:"
iptables -t mangle -I INPUT 1  -p tcp --dport 3333 \
-j LOG --log-prefix="mangle INPUT[0]:"
iptables -t mangle -I INPUT 1  -p tcp --sport 3333 \
-j LOG --log-prefix="mangle INPUT[1]:"
iptables -t mangle -A OUTPUT  -p tcp --dport 3333 \
-j LOG --log-prefix="mangle OUTPUT[0]:"
iptables -t mangle -A OUTPUT  -p tcp --sport 3333 \
-j LOG --log-prefix="mangle OUTPUT[1]:"
iptables -t mangle -I POSTROUTING 1  -p tcp --dport 3333 \
-j LOG --log-prefix="mangle POSTROUTING[0]:"
iptables -t mangle -I POSTROUTING 1  -p tcp --sport 3333 \
-j LOG --log-prefix="mangle POSTROUTING[1]:"
