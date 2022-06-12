#!/bin/bash
# https://developers.redhat.com/blog/2019/05/17/an-introduction-to-linux-virtual-interfaces-tunnels#sit_tunnel
# by default, calico use ipip mode to establish the connection between vm1's pod cidr to vm2's pod cidr
# modinfo tun

if [ $UID -ne 0 ]; then
    printf "%s need privilege to run script\n" $0
    exit 1
fi


function clean() {
    systemctl stop bird
}

function setup() {
    ############################ machine 1 (198.20.0.1 ) start #######################################
    export myarray=(`hostname -I`)
    if printf '%s\0' "${myarray[@]}" | grep -F -x -z "198.20.0.1" >/dev/null; then
        apt update && sudo apt install bird2 --yes
        cp -f /home/ubuntu/scripts/vm1-bird.conf /etc/bird/bird.conf
        systemctl restart bird
    fi


    ############################ machine 2 (198.20.0.2 ) start #######################################
    if printf '%s\0' "${myarray[@]}" | grep -F -x -z "198.20.0.2" >/dev/null; then
        apt update && sudo apt install bird2 --yes
        cp -f /home/ubuntu/scripts/vm2-bird.conf /etc/bird/bird.conf
        systemctl restart bird
    fi
}

usage() { echo "Usage: $0 [-c] [-q <blue>|<red>|<green>]" 1>&2; exit 1; }

# https://wiki.bash-hackers.org/howto/getopts_tutorial
# https://unix.stackexchange.com/questions/426483/what-is-the-purpose-of-the-very-first-character-of-the-option-string-of-getopts
while getopts ":cq:" OPTION; do
    case $OPTION in
    c)
        echo "cleaning ..."
        clean
        exit 0
        ;;
    q)
        COLOR=$OPTARG
        [[ ! $COLOR =~ BLUE|RED|GREEN ]] && {
            echo "Incorrect options provided"
            exit 1
        }
        ;;
    *)
        usage
        ;;
    esac
done
shift $((OPTIND-1))

echo "setup bird bgp ..."
setup
