#! /bin/sh

. /lib/ramips.sh

echo "[$0]dynamicly adjust cooling fan rotating speed according HDD temperature "
pcie2sata_hdd=""
hdd_standby=0

create_pid_file() {
        var=`ps | grep "/usr/sbin/hddmon.sh" | grep -v 'grep' | awk '{print $1}'`
        pid=`echo $var |awk '{print $1}'`
        echo $pid > /var/run/hddmon.sh.pid
}

esw_status_handler() {

	# do not handler it before system init done or HDD mounting done
	[ -f /tmp/sys_init_done ] || return
	[ -f /tmp/initdisk  ] && return
	
	update_LED_static_status
}

hard_drive_standby_handler() {
	hdd_standby=1
	hd-idle -t $pcie2sata_hdd
	echo "[$0] put $pcie2sata_hdd in standby"
	# detect HDD if sleep and turn on green led
	update_LED_static_status
	# lower fan speed
	fanup 22
}

create_pid_file
trap esw_status_handler SIGUSR1
trap hard_drive_standby_handler SIGUSR2

while [ 1 -eq 1 ]
do
	sd_dev_list=`ls /sys/block/ | grep sd`
	pcie2sata_hdd=""
	
	# get pcie connected drive
	for sd_dev in $sd_dev_list
	do
		/usr/sbin/sdtype.sh $sd_dev
		if [ $? -eq 1 ]; then
			pcie2sata_hdd=$sd_dev
			echo "[$0]pcie sata device $pcie2sata_hdd found"
			break
		fi
	done
	
	# no pcie connected drive, but turn on fan at low level
	[ -z "$pcie2sata_hdd" ] && fanup 22

	# get temperature and adjust cooling fan
	if [ -n "$pcie2sata_hdd" ] && [ $hdd_standby -eq 0 ]; then
		temperature=`/usr/sbin/smartctl -d sat -a /dev/$pcie2sata_hdd | grep Temperature_Celsius | awk '{print $10}' | tr -d '\n'`
		echo "[$0]$pcie2sata_hdd temperature is $temperature"
		if [ $temperature -gt 0 ] 2>/dev/null ;then
			echo "[$0]fanup $temperature"
			fanup $temperature
			# hard drive overheat,reboot system
			if [ $temperature -ge 60 ] ;then
				reboot
			fi
		else
			echo "[$0]error invalid temperature=\"$temperature\""
			# let fan run at low level
			fanup 22
			continue
		fi
	fi
	
	# check if hard drive come back to active/idle state, yes will resume query temperature
	if [ -n "$pcie2sata_hdd" ] && [ $hdd_standby -eq 1 ]; then
		hdd_status=`hdparm -C /dev/$pcie2sata_hdd 2>&1 | grep standby`

		# drive state change to active/idle
		if [ -z "$hdd_status" ]; then
			hdd_standby=0
			echo "[$0]/dev/$pcie2sata_hdd change to active/idle"
			
			# if SD is doing backup don't interfere
			if [ -f /tmp/sdbackup.pid ]; then
				backup_stat=$(cat /tmp/sdbackup.pid)

				if [ $backup_stat -ne 1 ]; then
					update_LED_static_status
				fi
			else
				update_LED_static_status
			fi
		fi
	fi
	
	sleep 10 & wait $!
done

exit 0
