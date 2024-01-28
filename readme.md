## GPU Passthrough Script

This script is used to start up a virtual machine for gaming with GPU passthrough. It is designed to be run on a Linux host system.

Below are some of my Resources
+ https://wiki.archlinux.org/index.php/PCI_passthrough_via_OVMF
+ https://gist.github.com/MaxXor/e24094f2b0624cf702f534f1a0dea0be
+ https://github.com/ValveSoftware/Proton/wiki/Using-a-NTFS-disk-with-Linux-and-Windows

### Prerequisites
- A Linux host system with a GPU that supports passthrough.
- A virtual machine configured for GPU passthrough.
- The virsh command-line tool for managing virtual machines.

__Usage__\
To use this script, simply run it from the command line with root priviliges.



### Configuration
The script requires the following environment variables to be set:

- VGA_DEVICE: The device identifier for the GPU passthrough.
- AUDIO_DEVICE: The device identifier for the HDMI audio passthrough.
- USB_DEVICE: (Optional) The device identifier for the USB controller passthrough.
- VM_NAME: (Optional) The name of the virtual machine.
- USERNAME: (Optional) The username of the user that will be used to run the looking-glass-client if you use it.
- MOUNT_POINT: (Optional) The mount point of the game drive that will be unmounted before starting the VM to be passed and remounted after shutting down the VM.

### How it Works
The script performs the following steps:

- Binds the specified GPU and audio device to the VFIO driver.
- Unmounts the game drive.
- Starts the specified virtual machine.
- Waits for the virtual machine to shut down.
- Unbinds the GPU and audio device from the VFIO driver.
- Rescans the PCI bus.
- Remounts the game drive.
- Prompts the user to restart the desktop environment.


#### Author
This script was created by 3c0m3x.
