#!/bin/bash

. env.sh

export myarray=(`hostname -I`)
if printf '%s\0' "${myarray[@]}" | grep -F -x -z "198.20.0.1" >/dev/null; then
    export BRIG_IP=$VM1_BRIG_IP
    export BRIG_GW=$VM1_BRIG_GW
    export BRIG_NET=$VM1_BRIG_NET
    export C1_IP=$VM1_C1_IP
    export C2_IP=$VM1_C2_IP
    export C1_NET=$VM1_C1_NET
    export C1_HOST=$VM1_C1_HOST
fi

if printf '%s\0' "${myarray[@]}" | grep -F -x -z "198.20.0.2" >/dev/null; then
    export BRIG_IP=$VM2_BRIG_IP
    export BRIG_GW=$VM2_BRIG_GW
    export BRIG_NET=$VM2_BRIG_NET
    export C1_IP=$VM2_C1_IP
    export C2_IP=$VM2_C2_IP
    export C1_NET=$VM2_C1_NET
    export C1_HOST=$VM2_C1_HOST
fi

clean() {
    sudo ip netns del netns_dustin  >/dev/null 2>&1 || true
    sudo ip netns del netns_leah >/dev/null 2>&1 || true

    sudo iptables -t nat -F POSTROUTING >/dev/null 2>&1 || true
    sudo iptables -t filter -F FORWARD  >/dev/null 2>&1 || true

    # stop the dynamic routes created by bird
    sudo systemctl stop bird >/dev/null 2>&1 || true
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

echo "setup infra ..."
# . setup.sh
. setup-slim.sh
