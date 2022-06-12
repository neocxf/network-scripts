#!/bin/bash
# https://developers.redhat.com/blog/2019/05/17/an-introduction-to-linux-virtual-interfaces-tunnels#sit_tunnel
# by default, calico use ipip mode to establish the connection between vm1's pod cidr to vm2's pod cidr
# modinfo tun

if [ $UID -ne 0 ]; then
    printf "%s need privilege to run script\n" $0
    exit 1
fi


function clean() {
   sudo ip l del dev ipip0
}

function setup() {
    ############################ machine 1 (198.20.0.1 ) start #######################################
    export myarray=(`hostname -I`)
    if printf '%s\0' "${myarray[@]}" | grep -F -x -z "198.20.0.1" >/dev/null; then
        ip link add name ipip0 type ipip local 198.20.0.1 remote 198.20.0.2
        ip link set ipip0 up
        ip addr add 10.42.1.1/24 dev ipip0
        ip route add 10.0.1.0/24 dev ipip0
    fi


    ############################ machine 2 (198.20.0.2 ) start #######################################
    if printf '%s\0' "${myarray[@]}" | grep -F -x -z "198.20.0.2" >/dev/null; then
        ip link add name ipip0 type ipip local 198.20.0.2 remote 198.20.0.1
        ip link set ipip0 up
        ip addr add 10.42.1.2/24 dev ipip0
        ip route add 10.0.0.0/24 dev ipip0
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

echo "setup ipip tunnel ..."
setup
