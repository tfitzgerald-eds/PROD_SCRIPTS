#!/bin/ksh
#
#	This is a rewrite of the script.  It is called by cronfifteen.ksh
#	every fifteen minutes, but instead of transfering files directly,
#	it executes script 'grab_a_file.ksh' on the destination server(s),
#	passing it appropriate parameters.
#
#	If LDAP client is down on abbott02 at the time the transfer is
#	attempted, the file transfer failure is processed, otherwise normal
#	procedure is executed.
#
#	File transfer history is kept via 'cksum' so that no file is processed
#	more than once, except by design.
#
#	The script runs only once per control list and destination server
#
exec 2>/tmp/$(basename $0 .ksh).trace.$(date '+%Y%m%d_%H%M%S')
set -x

trap 'rm -f /tmp/$$* /tmp/PID_*' EXIT				# cleanup on clean exit

COMMAND=$(basename $0)
LISTNAME=$1
LOCALDIR=$(echo $2|sed 's/\/$//')                               # strip the ending slash
DESTSERVER=$3		# not used as passed, all destinations re-extracted on invocation
LOCALUSER=$4		# this is not used, all transfers are done by dsuser
DESTDIR=$5		# same as $3
ARCDIR=$6		# same as $3
SCRIPTDIR=/ftp/common/scripts
HISTDIR=/ftp/common/history
OWNERS=/ftp/common/file_owners
TS=			# time-stamp variable to be used by subroutine

##################### performed functions start here #####################
send_file () {							# routine that transfers files once
set -x								# they pass duplicate check
MAXCC=0
cat  /tmp/$$.SERVERS|while read DESTSERVER
do								# send file to each destination server
								# passing the name of the list of destination
								# directories as the last parameter
	[ -f /tmp/sput_attempts/$LOCALFLE ] || \
		echo "0">/tmp/sput_attempts/$LOCALFLE		# to keep track of failures

	grep -w $DESTSERVER /tmp/$$.cf_extract|awk '{print $6}'|
		sed 's/\/$//'>/tmp/$$.$DESTSERVER.DESTDIR

	date>&2							# executing remote shell at this time
	ssh $DESTSERVER /home/dsuser/workdir/grab_a_file.ksh \
		$LOCALFLE $LOCALDIR /tmp/$$.$DESTSERVER.DESTDIR 2>/dev/null&
								# start in the background
	THISPID=$!						# process ID of the background job

	at now + 9 min 2>/tmp/PID_$THISPID<<-EOF		# terminate the job if it does
	kill $THISPID						# not come back within 9 minutes
	EOF
	wait $THISPID						# wait for background job to finish
	RC=$?
	MAXCC=$((MAXCC+RC))					# sum return codes

	date>&2							# time-stamp of when remote shell came back

	if [ $RC -eq 0 ]					# if successful, record history
	then							# and archive
		rm /tmp/sput_attempts/$LOCALFLE
		ATJOB=$(tail -1 /tmp/PID_$THISPID|awk '{print $2}')
		at -r $ATJOB 1>/dev/null			# make sure the 'at' job does not run
		rm -f /tmp/PID_$THISPID
	else
		TRIES=$(cat /tmp/sput_attempts/$LOCALFLE)
		TRIES=$((TRIES+1))
		echo "$TRIES">/tmp/sput_attempts/$LOCALFLE	# replace file
	fi
	sleep 1
done
return $MAXCC
}

handle_duplicate () {
	set -x
	echo "File $LOCALFLE already processed $HWHEN"|		# send mail
		mailx -s "File $LOCALFLE already processed $HWHEN" dmsdwprod
	ls -i $LOCALDIR/$LOCALFLE|awk '{print $1}'|read INODE	# inode of the file, unique within FS
	mv $LOCALDIR/$LOCALFLE /ftp/common/dups_received/$LOCALFLE.$INODE
}								# save into duplicates directory
								# with unique name
build_ts () {
	set -x
	cd $LOCALDIR						# manipulate the file
	typeset -Z2 DAY						# to have a suffix YYMMDD.HHMMSS
	istat $LOCALFLE|awk '/modified/ {print $4,$5,$6,substr($7,3)}'|read MON DAY SECS YR
	case $MON in
		Jan) print 01;;
		Feb) print 02;;
		Mar) print 03;;
		Apr) print 04;;
		May) print 05;;
		Jun) print 06;;
		Jul) print 07;;
		Aug) print 08;;
		Sep) print 09;;
		Oct) print 10;;
		Nov) print 11;;
		Dec) print 12;;
	esac|read NUM
	TS=$YR$NUM$DAY.$(echo $SECS|sed 's/://g')		# TS is the suffix
}

archive_file () {
	set -x
	ARCDIR=$(awk '{print $7}' /tmp/$$.cf_extract|grep -v empty|sort -u)
	[ -z "$ARCDIR" ] && return				# no archiving for this file

	cd $LOCALDIR						# rename the file
	build_ts						# to include the time-stamp
	mv $LOCALFLE $LOCALFLE.$TS				# rename the file
	ls -l $LOCALFLE.$TS|awk '{print $9,$5}'>>/ftp/files_sizes.txt # temporary for sizing
	compress $LOCALFLE.$TS					# compress it
	if [ $? -eq 0 ]						# archive it
	then
		mv $LOCALFLE.$TS.Z $ARCDIR
		ln -f $ARCDIR/$LOCALFLE.$TS.Z $ARCDIR/$LOCALFLE.Z.retain
	else
		mv $LOCALFLE.$TS $ARCDIR
		ln -f $ARCDIR/$LOCALFLE.$TS $ARCDIR/$LOCALFLE.retain
	fi
}
##################### performed functions end here #####################

cd $SCRIPTDIR
# next statement: temporary extract of all lines from cronfifteen script that use this list name
grep -v ^# cronfifteen.ksh|grep -w $COMMAND|grep -w $LISTNAME>/tmp/$$.cf_extract

awk '{print $4}' /tmp/$$.cf_extract|sort -u>/tmp/$$.SERVERS	# unique server names to receive files

cat $LISTNAME|while read LOCALFLE				# process each file in the list
do
	[ -f $LOCALDIR/$LOCALFLE ] || continue			# file does not exist
	fuser $LOCALDIR/$LOCALFLE|read INUSE
	[ -n "$INUSE" ] && continue				# file is in use, skip it

	cksum $LOCALDIR/$LOCALFLE|awk '{print $1,$2}'|read CKSUM
	if grep -wq "^$CKSUM" $HISTDIR/$LOCALFLE
	then
		if grep -wq $LOCALFLE /ftp/common/control/deny_dups
		then
			handle_duplicate
			continue
		fi
	fi

	send_file						# send the file to all destinations
	if [ $? -eq 0 ]						# archive the file after successful
	then							# transfer
		echo "$CKSUM $SIZE on $(date '+%Y%m%d at %H%M')">>$HISTDIR/$LOCALFLE
		ls -li $LOCALDIR/$LOCALFLE>>$OWNERS/$LOCALFLE	# file listing before archiving
		archive_file
#	else
								# no longer sending email on failures
								# a single email is sent once a day
								# with the contents of /tmp/sput_attempts
#		TRIES=$(cat /tmp/sput_attempts/$LOCALFLE)
#		case $TRIES in
#			3|6|9) echo "File $LOCALFLE did not transfer to all destinations, $TRIES attempts"|
#				mailx -s "File $LOCALDIR/$LOCALFLE transfer failure" dmsdwprod;; # send mail
#		esac						# send failure message every multiple
	fi							# of 3 attempts
done
