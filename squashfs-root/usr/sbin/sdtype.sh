#!/bin/sh

usage()
{
	echo "USAGE: $0 <device name>"
	echo "e.g.: $0 sda"
}

if [ $# != 1 ]; then
	usage
	exit 0
fi

sys_blk=`ls /sys/block/ | grep $1 | head -1`
if [ -z "$sys_blk" ] || [ ! -h /sys/block/$1 ]; then
	echo "scsi device \"$1\" not exist!"
	exit 0
fi

if [ -n "$(readlink -f /sys/block/$sys_blk | grep ata)" ]; then
	echo "pcie"
	exit 1
elif [ -n "$(readlink -f /sys/block/$sys_blk | grep xhci)" ]; then
	echo "usb"
	exit 2
else
	echo "neither"
fi

exit 0



