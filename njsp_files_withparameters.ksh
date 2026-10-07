#!/bin/ksh
#
#	Process NJSP files from the list in the control file, attempts
#		to send files to destination server(s) are made three times
#
#	Any file not sent by the third attempt is flagged
#

COMMAND=$(basename $0)
CONTROL=/ftp/common/control/$(basename $COMMAND .ksh)
NOW=$(date +%Y%m%d_%H%M)
exec 2>/tmp/$(basename $COMMAND .ksh).trace.$NOW
set -x

INDIR=$(grep INDIR= $CONTROL|awk -F= '{print $2}')
##DESTDIR=$(grep DESTDIR= $CONTROL|awk -F= '{print $2}')
DESTDIR=$1
REMSVR=$2
INFORM=$(grep INFORM= $CONTROL|awk -F= '{print $2}')
LOGS=$(dirname $INDIR)/logs
TEMP=$$

trap 'rm -f /tmp/$TEMP' EXIT

TODAY=$(date +%Y%m%d)
HR=$(date +%H)
##if [ $HR -eq 2 ]
##then
##	set -- $(grep -v ^# $CONTROL|grep -v "^$"|grep -v "="|awk '{print $2}'|sort -u)
##	for REMSVR in $*
##	do
##		>$LOGS/${REMSVR}_$TODAY		# initialize today's log(s)
##	done
##	shift $#
##fi

process_file () {
	set -x
	[ -s $FILE ] || return			# file did not arrive (yet?)

	fuser $FILE 1>/tmp/$TEMP 2>/dev/null
	TESTSIZE=$(ls -l /tmp/$TEMP|awk '{print $5}')
	[ $TESTSIZE -gt 0 ] && return		# transfer in progress, will try again

	scp -pq $FILE ${REMSVR}:$DESTDIR/		# send to destination
	RC=$?
	if [ $RC -eq 0 ]			# when successful
	then
		echo $FILE>>$LOGS/${REMSVR}_$TODAY	# log as sent
	fi
}

cd $INDIR
grep -v ^# $CONTROL|grep -v "^$"|grep -v "="|while read FILE 
do
	grep -wq $FILE $LOGS/${REMSVR}_$TODAY && continue	# already sent today
	process_file
done

if [ $HR -eq 4 ]
then
	grep -v ^# $CONTROL|grep -v "^$"|grep -v "="|while read FILE 
	do
		grep -wq $FILE $LOGS/${REMSVR}_$TODAY || echo $FILE>>$LOGS/notsent_$TODAY
	done
	if [ -s $LOGS/notsent_$TODAY ]
	then
		(echo "\n\nNJSP files not sent:\n"
		 cat $LOGS/notsent_$TODAY)|mailx -s "NJSP files not sent today" $INFORM
	else
		for FILE in $(ls|grep -v sent)
		do
			mv -f $FILE $FILE.sent
		done
	fi
fi
