#!/bin/bash

## made by 3c0m3x

clear
cat <<"EOF"

  _____                 _              __      ___      _               _   __  __            _     _            
 / ____|               (_)             \ \    / (_)    | |             | | |  \/  |          | |   (_)           
| |  __  __ _ _ __ ___  _ _ __   __ _   \ \  / / _ _ __| |_ _   _  __ _| | | \  / | __ _  ___| |__  _ _ __   ___ 
| | |_ |/ _` | '_ ` _ \| | '_ \ / _` |   \ \/ / | | '__| __| | | |/ _` | | | |\/| |/ _` |/ __| '_ \| | '_ \ / _ \
| |__| | (_| | | | | | | | | | | (_| |    \  /  | | |  | |_| |_| | (_| | | | |  | | (_| | (__| | | | | | | |  __/
 \_____|\__,_|_| |_| |_|_|_| |_|\__, |     \/   |_|_|   \__|\__,_|\__,_|_| |_|  |_|\__,_|\___|_| |_|_|_| |_|\___|
                                 __/ |                                                                           
                                |___/                                                                            
EOF

###############
# DEFINE VARS #
###############
# This script starts up a virtual machine with GPU passthrough. It requires the following variables:
# - DEVICE: The device identifier for the GPU passthrough.
# - HDMI_AUDIO_DEVICE: The device identifier for the HDMI audio passthrough.
# - USB_CONTROLLER: (Optional) The device identifier for the USB controller passthrough.
# - VM_NAME: The name of the virtual machine.
# - USERNAME: (Optional) The username of the user that will be used to run the looking-glass-client if you want to use it.
# - MOUNT_POINT: (Optional) The mount point of the game drive that will be unmounted before starting the VM to be passed and remounted after shutting down the VM.

# change these according to your system

export VGA_DEVICE=0000:12:00.0 #use lspci to find out the device id's
export AUDIO_DEVICE=0000:12:00.1
export VGA_DEVICE_ID=1002:73ff
export AUDIO_DEVICE_ID=1002:ab28
export USB_DEVICE=0000:30:00.4
export USB_DEVICE_ID=1022:1639
export VM_NAME='win11' #use virsh list --all to find out the vm name
export USERNAME='ecomex' #use whoami to find out your username
export MOUNT_POINT='/mnt/gamedisk' #use lsblk to find out the mount point of your game drive

#############
# FUNCTIONS #
#############

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

start_vm() {
    local vm_name="$1"  # The name of the VM is passed as the first parameter

    # Check if a VM name was provided
    if [ -z "$vm_name" ]; then
        echo "Error: No VM name provided."
        exit 1  # Exit the function with an error status
    fi

    # Check if the VM is already running
    if virsh list --name --state-running | grep -q "^$vm_name$"; then
        echo "Error: The VM '$vm_name' is already running."
        return 1  # Exit the function with an error status
    fi

    # Start the VM with the provided name
    echo "Starting VM: $vm_name"
    virsh start "$vm_name"

    # Check if the startup was successful
    if [ $? -eq 0 ]; then
        echo "VM '$vm_name' started successfully."
    else
        echo "Error starting VM '$vm_name'."
        exit 1  # Exit the function with an error status
    fi
}

wait_for_vm_shutdown() {
    local vm_name="$1"  # The name of the VM is passed as the first parameter

    # Check if a VM name was provided
    if [ -z "$vm_name" ]; then
        echo "Error: No VM name provided."
        return 1  # Exit the function with an error status
    fi

    # Wait for the VM to shut down
    echo "Waiting for VM to shut down: $vm_name"
    virsh domstate --domain "$vm_name" --reason | grep -qE 'shut off|ausgeschaltet'
    while [ $? -ne 0 ]; do
        sleep 10  # Wait for 5 seconds before checking again
        virsh domstate --domain "$vm_name" --reason | grep -qE 'shut off|ausgeschaltet'
    done

    echo "VM '$vm_name' has been shut down."
}

function unmount_gamedisk() {
    local mount_point="$1"  # The mount point is passed as the first parameter

    # Check if the game disk is mounted at the specified mount point
    if findmnt -M "$mount_point" > /dev/null; then
        echo "A file system is mounted at $mount_point. Attempting to unmount..."
        sudo umount "$mount_point"
        if [ $? -eq 0 ]; then
            echo "File system successfully unmounted."
        else
            echo "Error unmounting the file system."
            exit 1  # Exit the script
        fi
    else
        echo "No file system mounted at $mount_point."
    fi
}

function mount_gamedisk() {
    local mount_point="$1"  # The mount point is passed as the first parameter

    # Check if a filesystem is already mounted at the specified mount point
    if findmnt -M "$mount_point" > /dev/null; then
        echo "A filesystem is already mounted at $mount_point."
    else
        echo "No filesystem mounted at $mount_point. Attempting to mount..."
        sudo mount -a
        if [ $? -eq 0 ]; then
            echo "Filesystem successfully mounted at $mount_point."
        else
            echo "Error mounting filesystem at $mount_point."
            exit 1  # Exit the script
        fi
    fi
}

restart_desktop_env_prompt() {
    while true; do
        read -p "Do you want to restart the desktop environment? (Y/N) " answer

        case $answer in
            [Yy]* ) 
                echo "Restarting the desktop environment in:"
                for i in {5..1}; do
                    echo "$i..."
                    sleep 1
                done
                echo "Restarting the desktop environment..."
                systemctl restart sddm
                break
                ;;
            [Nn]* ) 
                echo "Restart declined."
                break
                ;;
            * ) 
                echo "Please answer with Y or N."
                ;;
        esac
    done
}

########
# MAIN #
########

# Display information about the specified graphics card and audio device
lspci -nnkd $VGA_DEVICE_ID && lspci -nnkd $AUDIO_DEVICE_ID # && lspci -nnkd $USB_DEVICE_ID 

# Bind specified graphics card and audio device to vfio
echo Binding specified graphics card and audio device to vfio

vfiobind $VGA_DEVICE
vfiobind $AUDIO_DEVICE
#vfiobind $USB_DEVICE

# Display information about the bound graphics card and audio device
lspci -nnkd $VGA_DEVICE_ID && lspci -nnkd $AUDIO_DEVICE_ID # && lspci -nnkd $USB_DEVICE_ID

# Unmount the game drive
echo "Unmounting game drive..."
unmount_gamedisk $MOUNT_POINT

sleep 5

# Start the virtual machine
start_vm $VM_NAME


# Start looking-glass-client if a username was provided
# uncomment the following lines if you want to use looking-glass-client

# if [ -n "$USERNAME" ]; then
#     echo "Starting looking-glass-client..."
#     sudo -u $USERNAME looking-glass-client
# fi

# Wait for the virtual machine to shut down
wait_for_vm_shutdown $VM_NAME

# Reload the host drivers for the passed-through devices
echo Adios vfio, reloading the host drivers for the passed-through devices...
echo "Rebinding in:"
for i in {5..1}; do
    echo "$i..."
    sleep 1
done

# Unbind the audio and graphics card from vfio
# Leave vfio-pci on the audio device
vfiounbind $AUDIO_DEVICE
vfiounbind $VGA_DEVICE
#vfiounbind $USB_DEVICE

# Rescan the PCI bus
pcirescan

# Display information about the unbound graphics card and audio device
lspci -nnkd $VGA_DEVICE_ID && lspci -nnkd $AUDIO_DEVICE_ID # && lspci -nnkd $USB_DEVICE_ID

# Mount the game drive
echo "Mounting game drive..."
mount_gamedisk $MOUNT_POINT

# Prompt to restart the desktop environment
restart_desktop_env_prompt

echo "Done!"
