#!/bin/ksh
exec 1>/$HOME/$(basename $0 .ksh).log
while :
do
	for SERVER in barton40 robeson40 robeson41 robeson42
	do
		date
		ping -c2 -w1 $SERVER
	done
	TIME=$(date +%H%M)
	[ $TIME -gt 259 ] && break 2
	sleep 10
done
