#!/bin/bash

## Virsh devices
VIRSH_GPU_VIDEO='0000:12:00.0'
VIRSH_GPU_AUDIO='0000:12:00.1'
VIRSH_GPU_USB='0000:30:00.4'


sleep 5 &&

## Unload vfio
modprobe -r vfio_pci
modprobe -r vfio_iommu_type1
modprobe -r vfio

sleep 5 &&

## Unbind gpu from vfio and bind to nvidia
echo 1 > /sys/bus/pci/devices/${VIRSH_GPU_VIDEO}/remove
echo 1 > /sys/bus/pci/devices/${VIRSH_GPU_AUDIO}/remove
echo 1 > /sys/bus/pci/devices/${VIRSH_GPU_USB}/remove
echo 1 > /sys/bus/pci/rescan

