#!/bin/ksh
LOG=$HOME/$(basename $0 .ksh).log
exec 1>$LOG
while :
do
	for SERVER in barton40 robeson40 robeson41 robeson42
	do
		echo $SERVER $(date)
		ssh -q $SERVER <<-EOF 1>/dev/null 2>/dev/null
		exit
		EOF
		echo RC=$?
	done
	TIME=$(date +%H%M)
	[ $TIME -gt 559 ] && break 2
	sleep 30
done
grep -q 255 $LOG && mv $LOG sshlogs/$LOG.$(date +%Y%m%d)
