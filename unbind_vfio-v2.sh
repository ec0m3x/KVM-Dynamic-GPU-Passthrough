#!/bin/bash

export VGA_DEVICE=0000:12:00.0
export AUDIO_DEVICE=0000:12:00.1
export VGA_DEVICE_ID=1002:73ff
export AUDIO_DEVICE_ID=1002:ab28

vfiounbind() {
	DEV="$1"

	echo -n Unbinding VFIO from ${DEV}...

	echo > /sys/bus/pci/devices/${DEV}/driver_override
	#echo ${DEV} > /sys/bus/pci/drivers/vfio-pci/unbind
	echo 1 > /sys/bus/pci/devices/${DEV}/remove
	sleep 0.2

	echo OK!
}

pcirescan() {

	echo -n Rescanning PCI bus...

	su -c "echo 1 > /sys/bus/pci/rescan"
	sleep 0.2

	echo OK!

}

echo Adios vfio, reloading the host drivers for the passedthrough devices...

sleep 0.5

# Don't unbind audio, because it fucks up for whatever reason.
# Leave vfio-pci on it.
vfiounbind $AUDIO_DEVICE
vfiounbind $VGA_DEVICE

pcirescan

lspci -nnkd $VGA_DEVICE_ID && lspci -nnkd $AUDIO_DEVICE_ID