#!/bin/bash

export VGA_DEVICE=0000:12:00.0
export AUDIO_DEVICE=0000:12:00.1
export VGA_DEVICE_ID=1002:73ff
export AUDIO_DEVICE_ID=1002:ab28

vfiobind() {
	DEV="$1"

	# Check if VFIO is already bound, if so, return.
	VFIODRV="$( ls -l /sys/bus/pci/devices/${DEV}/driver | grep vfio )"
	if [ -n "$VFIODRV" ];
	then
		echo VFIO was already bound to this device!
		return 0
	fi

	echo -n Binding VFIO to ${DEV}...

	echo ${DEV} > /sys/bus/pci/devices/${DEV}/driver/unbind
	sleep 0.5

	echo vfio-pci > /sys/bus/pci/devices/${DEV}/driver_override
	echo ${DEV} > /sys/bus/pci/drivers/vfio-pci/bind
	# echo > /sys/bus/pci/devices/${DEV}/driver_override

	sleep 0.5

	echo OK!
}


lspci -nnkd $VGA_DEVICE_ID && lspci -nnkd $AUDIO_DEVICE_ID
# Bind specified graphics card and audio device to vfio.
echo Binding specified graphics card and audio device to vfio

vfiobind $VGA_DEVICE
vfiobind $AUDIO_DEVICE

lspci -nnkd $VGA_DEVICE_ID && lspci -nnkd $AUDIO_DEVICE_ID