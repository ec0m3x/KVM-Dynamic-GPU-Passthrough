#!/bin/bash

## Virsh devices
VIRSH_GPU_VIDEO=pci_0000_12_00_0
VIRSH_GPU_AUDIO=pci_0000_12_00_1
VIRSH_GPU_USB=pci_0000_30_00_4

## Load vfio
modprobe vfio
modprobe vfio_iommu_type1
modprobe vfio_pci

## Unbind gpu from nvidia and bind to vfio
virsh nodedev-detach $VIRSH_GPU_VIDEO
virsh nodedev-detach $VIRSH_GPU_AUDIO
virsh nodedev-detach $VIRSH_GPU_USB
