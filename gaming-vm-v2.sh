#!/bin/bash
#set -e

###############
# DEFINE VARS #
###############
# Which device and which related HDMI audio device. They're usually in pairs.
export VGA_DEVICE=0000:12:00.0
export AUDIO_DEVICE=0000:12:00.1
export VGA_DEVICE_ID=1002:73ff
export AUDIO_DEVICE_ID=1002:ab28
export USB_DEVICE=0000:30:00.4
export USB_DEVICE_ID=1022:1639
export VM_NAME='win11'
export USERNAME='ecomex'

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
    local vm_name="$1"  # Der Name der VM wird als erster Parameter übergeben

    # Überprüfen, ob ein VM-Name angegeben wurde
    if [ -z "$vm_name" ]; then
        echo "Fehler: Kein VM-Name angegeben."
        return 1  # Beendet die Funktion mit einem Fehlerstatus
    fi

    # Starten der VM mit dem angegebenen Namen
    echo "Starte VM: $vm_name"
    virsh start "$vm_name"

    # Überprüfen, ob der Startvorgang erfolgreich war
    if [ $? -eq 0 ]; then
        echo "VM '$vm_name' erfolgreich gestartet."
    else
        echo "Fehler beim Starten der VM '$vm_name'."
        return 1  # Beendet die Funktion mit einem Fehlerstatus
    fi
}


wait_for_vm_shutdown() {
    local vm_name="$1"  # Der Name der VM wird als erster Parameter übergeben

    # Überprüfen, ob ein VM-Name angegeben wurde
    if [ -z "$vm_name" ]; then
        echo "Fehler: Kein VM-Name angegeben."
        return 1  # Beendet die Funktion mit einem Fehlerstatus
    fi

    # Warten, bis die VM heruntergefahren ist
    echo "Warte auf das Herunterfahren der VM: $vm_name"
    virsh domstate --domain "$vm_name" --reason | grep -q 'ausgeschaltet'
    while [ $? -ne 0 ]; do
        sleep 10  # Wartet 5 Sekunden bevor erneut geprüft wird
        virsh domstate --domain "$vm_name" --reason | grep -q 'ausgeschaltet'
    done

    echo "VM '$vm_name' wurde heruntergefahren."
}

restart_desktop_env_prompt() {
    while true; do
        read -p "Möchten Sie die Desktopumgebung neu starten? (J/N) " answer

        case $answer in
            [Jj]* ) 
                echo "Neustart der Desktopumgebung in:"
                for i in {5..1}; do
                    echo "$i..."
                    sleep 1
                done
                echo "Neustart der Desktopumgebung..."
                systemctl restart sddm
                break
                ;;
            [Nn]* ) 
                echo "Neustart abgelehnt."
                break
                ;;
            * ) 
                echo "Bitte antworten Sie mit J oder N."
                ;;
        esac
    done
}

########
# MAIN #
########

lspci -nnkd $VGA_DEVICE_ID && lspci -nnkd $AUDIO_DEVICE_ID && lspci -nnkd $USB_DEVICE_ID
# Bind specified graphics card and audio device to vfio.
echo Binding specified graphics card and audio device to vfio

vfiobind $VGA_DEVICE
vfiobind $AUDIO_DEVICE
vfiobind $USB_DEVICE

lspci -nnkd $VGA_DEVICE_ID && lspci -nnkd $AUDIO_DEVICE_ID && lspci -nnkd $USB_DEVICE_ID

sleep 5

start_vm $VM_NAME

su $USERNAME -c "looking-glass-client -F"

wait_for_vm_shutdown $VM_NAME

echo Adios vfio, reloading the host drivers for the passedthrough devices...
echo "Rebinding in:"
for i in {5..1}; do
    echo "$i..."
    sleep 1
done

# Don't unbind audio, because it fucks up for whatever reason.
# Leave vfio-pci on it.
vfiounbind $AUDIO_DEVICE
vfiounbind $VGA_DEVICE
vfiounbind $USB_DEVICE

pcirescan

lspci -nnkd $VGA_DEVICE_ID && lspci -nnkd $AUDIO_DEVICE_ID && lspci -nnkd $USB_DEVICE_ID

restart_desktop_env_prompt

