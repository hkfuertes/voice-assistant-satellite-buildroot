#!/bin/sh

GADGET_PATH="/sys/kernel/config/usb_gadget/g1"
CONFIG_FILE="/etc/usb-gadget.conf"
USB_IP="192.168.42.1"
USB_NETMASK="24"

log() {
	echo "$(date '+%Y-%m-%d %H:%M:%S') $@"
	logger -t usb-gadget "$@" 2>/dev/null || true
}

load_config() {
	if [ -f "$CONFIG_FILE" ]; then
		. "$CONFIG_FILE"
	fi
	: ${USE_NCM:=1}
	: ${ENABLE_ACM:=1}
}

get_serial_number() {
	if [ -f /proc/cpuinfo ]; then
		grep Serial /proc/cpuinfo | cut -d' ' -f2 | cut -c9-16
	elif [ -f /etc/machine-id ]; then
		cat /etc/machine-id | head -c 16
	else
		echo "0123456789abcdef"
	fi
}

generate_mac_address() {
	local prefix="$1"
	local serial="$(get_serial_number)"
	local hash="$(echo -n "${serial}${prefix}" | md5sum | cut -c1-12)"
	
	local b1="$(echo ${hash} | cut -c1-2)"
	local b2="$(echo ${hash} | cut -c3-4)"
	local b3="$(echo ${hash} | cut -c5-6)"
	local b4="$(echo ${hash} | cut -c7-8)"
	local b5="$(echo ${hash} | cut -c9-10)"
	local b6="$(echo ${hash} | cut -c11-12)"
	
	b1="$(printf '%02x' $((0x${b1} & 0xfe | 0x02)))"
	
	echo "${b1}:${b2}:${b3}:${b4}:${b5}:${b6}"
}

configure_network() {
	log "Configuring usb0 network interface"
	
	for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
		if [ -d "/sys/class/net/usb0" ]; then
			break
		fi
		sleep 1
	done
	
	if [ ! -d "/sys/class/net/usb0" ]; then
		log "WARNING: usb0 interface not found"
		return 1
	fi
	
	ip addr flush dev usb0 2>/dev/null
	ip link set usb0 down 2>/dev/null
	sleep 1
	ip link set usb0 up
	ip addr add ${USB_IP}/${USB_NETMASK} dev usb0
	
	if ip addr show usb0 | grep -q "${USB_IP}"; then
		log "Network configured: usb0 ${USB_IP}/${USB_NETMASK}"
		return 0
	else
		log "ERROR: Failed to assign IP to usb0"
		return 1
	fi
}

start_serial_console() {
	# Wait for ttyGS0
	for i in 1 2 3 4 5; do
		if [ -c "/dev/ttyGS0" ]; then
			break
		fi
		sleep 1
	done
	
	if [ -c "/dev/ttyGS0" ]; then
		log "Starting serial console on ttyGS0"
		# Kill existing getty if any
		pkill -f "getty.*ttyGS0" 2>/dev/null
		# Start getty on ttyGS0
		/sbin/getty -L ttyGS0 115200 vt100 &
		return 0
	else
		log "WARNING: ttyGS0 not found"
		return 1
	fi
}

setup_gadget() {
	load_config
	
	log "Setting up USB composite gadget (Network + Serial)"
	
	MAC_HOST=$(generate_mac_address "host")
	MAC_DEV=$(generate_mac_address "dev")
	
	modprobe libcomposite 2>/dev/null || true
	
	if ! mountpoint -q /sys/kernel/config; then
		mount -t configfs none /sys/kernel/config || {
			log "ERROR: Failed to mount configfs"
			return 1
		}
	fi
	
	if [ ! -d "/sys/class/udc" ] || [ -z "$(ls /sys/class/udc/)" ]; then
		modprobe dwc2 2>/dev/null || true
		sleep 2
		if [ ! -d "/sys/class/udc" ] || [ -z "$(ls /sys/class/udc/)" ]; then
			log "ERROR: No UDC available"
			return 1
		fi
	fi
	
	mkdir -p "${GADGET_PATH}"
	cd "${GADGET_PATH}"
	
	echo "0x1d6b" > idVendor
	echo "0x0104" > idProduct
	echo "0x0100" > bcdDevice
	echo "0x0200" > bcdUSB
	echo "0xEF" > bDeviceClass
	echo "0x02" > bDeviceSubClass
	echo "0x01" > bDeviceProtocol
	
	mkdir -p strings/0x409
	echo "$(get_serial_number)" > strings/0x409/serialnumber
	echo "Buildroot" > strings/0x409/manufacturer
	echo "USB Multifunction Device" > strings/0x409/product
	
	mkdir -p configs/c.1/strings/0x409
	echo "CDC + ACM" > configs/c.1/strings/0x409/configuration
	echo "250000" > configs/c.1/MaxPower
	echo "0xc0" > configs/c.1/bmAttributes
	
	# ACM Serial function (always enabled)
	log "Configuring ACM serial console"
	mkdir -p functions/acm.usb0
	ln -s functions/acm.usb0 configs/c.1/
	
	# Network function
	if [ "$USE_NCM" = "1" ]; then
		log "Configuring NCM network - Host: $MAC_HOST, Dev: $MAC_DEV"
		mkdir -p functions/ncm.usb1
		echo "$MAC_HOST" > functions/ncm.usb1/host_addr
		echo "$MAC_DEV" > functions/ncm.usb1/dev_addr
		ln -s functions/ncm.usb1 configs/c.1/
	else
		log "Configuring RNDIS network - Host: $MAC_HOST, Dev: $MAC_DEV"
		mkdir -p functions/rndis.usb1
		echo "$MAC_HOST" > functions/rndis.usb1/host_addr
		echo "$MAC_DEV" > functions/rndis.usb1/dev_addr
		ln -s functions/rndis.usb1 configs/c.1/
		
		echo 1 > os_desc/use 2>/dev/null || true
		echo 0xcd > os_desc/b_vendor_code 2>/dev/null || true
		echo MSFT100 > os_desc/qw_sign 2>/dev/null || true
		ln -s configs/c.1 os_desc 2>/dev/null || true
	fi
	
	UDC=$(ls /sys/class/udc/ | head -1)
	if [ -z "$UDC" ]; then
		log "ERROR: No UDC controller found"
		return 1
	fi
	
	echo "$UDC" > UDC || {
		log "ERROR: Failed to bind to UDC $UDC"
		return 1
	}
	
	log "USB gadget enabled on $UDC"
	
	# Start serial console
	start_serial_console
	
	# Configure network
	configure_network
	
	return 0
}

teardown_gadget() {
	log "Tearing down USB gadget"
	
	# Stop getty
	pkill -f "getty.*ttyGS0" 2>/dev/null || true
	
	# Deconfigure network
	if [ -d "/sys/class/net/usb0" ]; then
		ip addr flush dev usb0 2>/dev/null
		ip link set usb0 down 2>/dev/null
	fi
	
	[ ! -d "${GADGET_PATH}" ] && return 0
	
	cd "${GADGET_PATH}"
	
	echo "" > UDC 2>/dev/null || true
	sleep 1
	
	rm -f configs/c.1/acm.usb0 2>/dev/null || true
	rm -f configs/c.1/ncm.usb1 2>/dev/null || true
	rm -f configs/c.1/rndis.usb1 2>/dev/null || true
	rm -f os_desc/c.1 2>/dev/null || true
	rmdir configs/c.1/strings/0x409 2>/dev/null || true
	rmdir configs/c.1 2>/dev/null || true
	
	rmdir functions/acm.usb0 2>/dev/null || true
	rmdir functions/ncm.usb1 2>/dev/null || true
	rmdir functions/rndis.usb1 2>/dev/null || true
	
	rmdir strings/0x409 2>/dev/null || true
	cd ..
	rmdir g1 2>/dev/null || true
}

status() {
	load_config
	
	echo "Configuration:"
	echo "  Network: $([ "$USE_NCM" = "1" ] && echo "NCM" || echo "RNDIS")"
	echo "  Serial: Enabled (ttyGS0)"
	echo "  IP: ${USB_IP}/${USB_NETMASK}"
	echo ""
	
	if [ -d "${GADGET_PATH}" ] && [ -s "${GADGET_PATH}/UDC" ]; then
		echo "USB Gadget: Active"
		echo "UDC: $(cat ${GADGET_PATH}/UDC)"
		
		if [ -c "/dev/ttyGS0" ]; then
			echo "Serial: ttyGS0 available"
			pgrep -f "getty.*ttyGS0" >/dev/null && echo "  getty: running" || echo "  getty: not running"
		fi
		
		if [ -d "/sys/class/net/usb0" ]; then
			echo ""
			echo "Network usb0:"
			ip -br addr show usb0 2>/dev/null || ip addr show usb0 | grep 'inet\|state'
		fi
		return 0
	else
		echo "USB Gadget: Inactive"
		return 1
	fi
}

case "$1" in
	start)
		teardown_gadget
		setup_gadget
		;;
	stop)
		teardown_gadget
		;;
	restart)
		teardown_gadget
		sleep 1
		setup_gadget
		;;
	status)
		status
		;;
	*)
		echo "Usage: $0 {start|stop|restart|status}"
		exit 1
		;;
esac
