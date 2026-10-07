#!/bin/ksh
trap 'rm -f /tmp/$$* /tmp/target_compare' EXIT
exec 2>/tmp/$(basename $0 .ksh).trace.$(date +%Y%m%d)
set -x
CONTROL=/ftp/common/control
LOCALDIR=$(grep -w ^LOCALDIR $CONTROL/$(basename $0 .ksh)|awk -F= '{print $2}')
ARCDIR=$(grep -w ^ARCDIR $CONTROL/$(basename $0 .ksh)|awk -F= '{print $2}')
OWNERS=$(grep -w ^OWNERS $CONTROL/$(basename $0 .ksh)|awk -F= '{print $2}')
DESTDIR=$(grep -w ^DESTDIR $CONTROL/$(basename $0 .ksh)|awk -F= '{print $2}')
SUBJECT=$(grep -w ^SUBJECT $CONTROL/$(basename $0 .ksh)|awk -F= '{print $2}')
TIMESTAMP=$(grep -w ^TIMESTAMP $CONTROL/$(basename $0 .ksh)|awk -F= '{print $2}')
DESTSVR=$(echo $DESTDIR|awk -F: '{print $1}')
HISTDIR=/ftp/common/history
PATH=$PATH:/home/dsuser/mikev/bin
YESTERDAY=$(20210304)
NOW=$(date +%H%M)
touch -t $YESTERDAY$NOW /tmp/target_compare		# 24 hours ago

[ $TIMESTAMP = Y ] && TS=$(date +.%Y%m%d) || TS=

rm -f /tmp/$$*						# make sure temporary files do not exist

cd $LOCALDIR
ls|while read OLDNAME
do
	[ -f "$OLDNAME" ] || continue			# not a regular file
	[ "$OLDNAME" -nt /tmp/target_compare ] || continue	# file not received within 24 hours
	echo $OLDNAME|sed 's/_/ /g'|			# replace underscores with spaces
	awk '{N=split($0,A)				# file names received are not always
	      for (i=1;i<=N-3;i++)			# in the proper format
		printf "%s_",A[i]
	      print A[N-2] ".csv",A[N-1]		# next to last token should be the month name
	     }'|read NEWNAME MONTH			# either abreviated, or full

	echo $MONTH|awk '{print substr($1,1,3)}'|read MTH	# make sure we have the abreviated name
	[ -z "$MTH" ] && continue			# empty string, should not happen, but...
	grep -qi $MTH $CONTROL/month_names || continue	# a valid month name not part of the file name

	ln -f "$OLDNAME" $NEWNAME			# create a link dropping year and month 
							# from the file name

	[ -f $HISTDIR/$NEWNAME ] || >$HISTDIR/$NEWNAME	# create the history file first time around
	cksum $NEWNAME|awk '{print $1,$2}'|read CKSUM
	grep -wq "^$CKSUM" $HISTDIR/$NEWNAME && continue	# skip if already processed
	DESTNAME=$(echo $NEWNAME|sed "s/.csv/$TS.csv/")
	scp -p $NEWNAME $DESTDIR/$DESTNAME 2>/dev/null
	RC=$?
	if [ $RC -ne 0 ]
	then
		echo "Transfer of $NEWNAME to $DESTDIR failed"|
			mailx -s "Transfer of $NEWNAME to $DESTDIR failed" etlgp
		exit
	fi
	echo $NEWNAME>>/tmp/$$
	ls -l $LOCALDIR/$NEWNAME>>$OWNERS/$NEWNAME
	echo "$CKSUM on $(date '+%Y%m%d at %H%M')">>$HISTDIR/$NEWNAME

	ARCTS=$(date +%Y%m%d.%H%M)			# begin archiving process
	rm $NEWNAME					# remove the link
	echo "$OLDNAME"|sed "s/.csv/.$ARCTS.csv/"|read ARCNAME
	mv "$OLDNAME" "$ARCNAME"			# rename original to unque name
	compress "$ARCNAME"
	if [ $? -eq 0 ]
	then
		mv "$ARCNAME.Z" $ARCDIR
	fi
		mv "$ARCNAME" $ARCDIR
done
[ -s /tmp/$$ ] || exit
cat /tmp/$$|mailx -s "$SUBJECT file(s) sent to $DESTSVR" etlgp
