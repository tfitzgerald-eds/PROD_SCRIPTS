#!/bin/ksh
#
#	Script runs once daily loking for billing file
#	exits if not present
#
#	Runs from cron daily at 8:45 ahead of the 9:00 DataStage
#	job on barton40
#
exec 2>/tmp/$(basename $0 .ksh).trace
set -x

cd /ftp/DMSCARS/ftp
if [ -s StateOfNewJerseyBilling* ]
then
	FILE=$(ls StateOfNewJerseyBilling*)
else
	exit
fi

RC=0
scp -pq $FILE barton40:/etl/DMSCARS/ftp/StateOfNewJerseyBilling_RRD_Print.csv 2>/dev/null
RC=$RC+$?
scp -pq $FILE Oidstag2his:/dsdata/DMSCARS/prod/ftp/StateOfNewJerseyBilling_RRD_Print.csv 2>/dev/null
RC=$RC+$?
scp -pq $FILE Oidstag1hie:/dsdata/DMSCARS/prod/ftp/StateOfNewJerseyBilling_RRD_Print.csv 2>/dev/null
RC=$RC+$?



if [ $RC -eq 0 ]
then
	compress $FILE
	if [ $? -eq 0 ]
	then
		mv $FILE.Z ../archives
	else
		mv $FILE ../archives
	fi
fi
