## GPU Passthrough Script

This script is used to start up a virtual machine with GPU passthrough. It is designed to be run on a Linux host system.

### Prerequisites
A Linux host system with a GPU that supports passthrough.
A virtual machine configured for GPU passthrough.
The virsh command-line tool for managing virtual machines.
Usage
To use this script, simply run it from the command line:



### Configuration
The script requires the following environment variables to be set:

- VGA_DEVICE: The device identifier for the GPU passthrough.\
- AUDIO_DEVICE: The device identifier for the HDMI audio passthrough.\
- VGA_DEVICE_ID: The device ID for the GPU passthrough.\
- AUDIO_DEVICE_ID: The device ID for the HDMI audio passthrough.\
- USB_DEVICE: (Optional) The device identifier for the USB controller passthrough.\
- USB_DEVICE_ID: (Optional) The device ID for the USB controller passthrough.\
- VM_NAME: (Optional) The name of the virtual machine.\
- USERNAME: (Optional) The username of the user that will be used to run the looking-glass-client if you use it.\
- MOUNT_POINT: (Optional) The mount point of the game drive that will be unmounted before starting the VM to be passed and remounted after shutting down the VM.

### How it Works
The script performs the following steps:

- Binds the specified GPU and audio device to the VFIO driver.
- Unmounts the game drive.\
- Starts the specified virtual machine.\
- Waits for the virtual machine to shut down.\
- Unbinds the GPU and audio device from the VFIO driver.\
- Rescans the PCI bus.\
- Remounts the game drive.\
- Prompts the user to restart the desktop environment.\


#### Author
This script was created by 3c0m3x.