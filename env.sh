#!/bin/sh

export PTP_GW=10.10.0.1
export PTP_NET=10.10.0.0

export NS=c1
export PTP_CIP=10.10.0.2
export PTP_VETH=veth0
export PTP_CETH=ceth0


export BRG_GW=10.10.0.1
export BRG_NET=10.10.0.0
export BRG_NAME=brg_0
export BRG_CIP=10.10.0.2
export BRG_VETH=veth0
export BRG_CETH=ceth0
export BRG_PORT=3333

alias ipt="iptables"
alias ipl="iptables -nvL --line-numbers"
alias iplt="iptables -t nat -nvL --line-numbers"
alias iplm="iptables -t mangle -nvL --line-numbers"
alias ipf="iptables -F"
alias ipfn="iptables -t nat -F"
alias ipfm="iptables -t mangle -F"