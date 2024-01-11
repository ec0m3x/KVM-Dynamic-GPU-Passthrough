#!/bin/bash
set -e

###############
# DEFINE VARS #
###############
PCI_ID='0000:12:00.0'
PCI_ID_2='0000:12:00.1'
PCI_ID_3='0000:30:00.4'
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
BIND_VFIO="$SCRIPT_DIR/bind_vfio.sh"
UNBIND_VFIO="$SCRIPT_DIR/unbind_vfio.sh"
VM_NAME='win11'
DRIVER_GPU='amdgpu'
DRIVER_VFIO='vfio-pci'

assign_driver_to_vfio() {
    echo -e "\n Assigning ${PCI_ID} to VFIO:\n"
    if [[ -e "/sys/bus/pci/devices/${PCI_ID}/driver" ]]; then
        CURRENT_DRIVER=$(readlink "/sys/bus/pci/devices/${PCI_ID}/driver" | sed 's/.*\/drivers\///')
        case ${CURRENT_DRIVER} in
            ${DRIVER_VFIO})
                echo -e " -- ${PCI_ID} is already assigned driver (${DRIVER_VFIO}).  Nothing to do.\n"
                ;;
            ${DRIVER_GPU})
                sudo bash ${BIND_VFIO} > /dev/null || echo " -- ERROR: Unable to assign ${PCI_ID} to ${DRIVER_VFIO}."
                echo -e " -- ${PCI_ID} successfully assigned driver (${DRIVER_VFIO}).\n"
                ;;
            *)
                echo -e " -- ERROR: Unexpected driver (${CURRENT_DRIVER}) assigned, no action taken.\n"
                ;;
        esac
    fi
}

start_vm() {
    echo -e "\nLaunching VM (${VM_NAME}):\n"
    VM_STATUS=$(sudo virsh list --all | grep "${VM_NAME}" | colrm 1 14)
    if [[ ${VM_STATUS} == 'ausgeschaltet' ]]; then
        sudo virsh start ${VM_NAME} > /dev/null 2>&1 || echo " -- ERROR: Unable to start ${VM_NAME}"
    else
        echo " -- ${VM_NAME} is already running."
    fi
}

wait_for_vm_shutdown() {
    echo -e "\n Waiting on VM (${VM_NAME}) to shutdown...\n"
    VM_ONLINE=$(sudo virsh list --all | grep "${VM_NAME}" | colrm 1 14)
    while [[ ${VM_ONLINE} != 'ausgeschaltet' ]]; do
        sleep 1
        VM_ONLINE=$(sudo virsh list --all | grep "${VM_NAME}" | colrm 1 14)
    done
    echo -e " -- VM (${VM_NAME}) is now off.\n"
}

reassign_gpu_to_host() {
    echo -n -e '\n Reassign GPU to host? [Y,N]:'
    read -r ASSIGN_TO_HOST
    case ${ASSIGN_TO_HOST} in
        'y' | 'Y')
            echo " Assigning ${PCI_ID} to Host"
            sudo bash ${UNBIND_VFIO} > /dev/null || echo " -- ERROR: Unable to reassign ${PCI_ID} to ${DRIVER_GPU}."
            echo " -- ${PCI_ID} successfully assigned driver (${DRIVER_GPU})."
            ;;
        'n' | 'N')
            echo " -- Skipping GPU reassignment to host"
            ;;
        *)
            echo " -- Response not understood, skipping GPU reassignment to host"
            ;;
    esac
}

# Hauptteil des Skripts
assign_driver_to_vfio
start_vm
looking-glass-client -F > /dev/null 2>&1
wait_for_vm_shutdown
reassign_gpu_to_host

echo -e '\n Finished...\n'
read -p "Press enter to exit"
exit
