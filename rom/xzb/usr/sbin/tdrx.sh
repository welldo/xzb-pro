#! /bin/sh
tdate=`date`
if [ -d "/data/UsbDisk1/Volume1" ] ;then
   logdir="/data/UsbDisk1/Volume1"
else
   logdir="/root"
 fi
if [ -z $1 ] ;then
        tdlimit=100
else
        tdlimit=$1
fi
thunderrx=`vnstat -tr -ru | grep rx | awk '{print $2}' | tr -d '\n' `
echo $thunderrx  $tdlimit
if [ ${thunderrx%.*}  -gt $tdlimit ] ;then
	echo "1-"$tdate"---:"$thunderrx "KB/s" >> $logdir/a.txt
	return 1
else
	echo "0-"$tdate"---:"$thunderrx "KB/s" >> $logdir/b.txt
	return 0
fi

