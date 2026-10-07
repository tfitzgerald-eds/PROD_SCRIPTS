#!/bin/ksh
exec 2>/tmp/$(basename $0 .ksh).trace.$(date +%Y%m%d_%H%M)
set -x
# sput_newfiles_norename.ksh
# complete rewrite 4/2017: accepts the same 7 passed parameters as the predecesor
#
FILELIST=$1
LOCALDIR=$2
REMOTESERVER=$3				# reset dynamically by this script
REMOTESERVERUSER=$4			# not used by this version, all transfers are done by 'dsuser'
REMOTEDIR=$5
REMOTEFILENAME=$6
ARCDIR=$7

SCRIPTDIR=/ftp/common/scripts
HISTDIR=/ftp/common/history
OWNERS=/ftp/common/file_owners
TS=                     		# time-stamp variable to be used by subroutine

######################## subroutines start here ######################################
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
	cd $LOCALDIR
	build_ts
	mv $LOCALFLE $LOCALFLE.$TS				# rename the file
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

check_duplicate () {
[ -f $HISTDIR/$LOCALFLE ] || >$HISTDIR/$LOCALFLE
						# create empty history file if it does not exist

cksum $LOCALDIR/$LOCALFLE|awk '{print $1,$2}'|read CKSUM
grep -w "^$CKSUM" $HISTDIR/$LOCALFLE|tail -1|awk '{print $1,$2}'|read ANS
if [ -n "$ANS" ] 				# variable is not null, this file was previosly sent
then
	grep -w "^$CKSUM" $HISTDIR/$LOCALFLE|tail -1|mailx -s "$LOCALFLE: Duplicate not sent" mvv	# etlgp ja mvv
	exit
fi

}
######################## subroutines end here ######################################

cd $SCRIPTDIR
[ -s "$FILELIST" ] || exit			# mk_wildcard_filelist.ksh did not find any files
						# to match wildcard, the list is empty

shift $#					# clear parameter list to build a new one containing destinations
set -- $(grep -w $FILELIST cronfifteen.ksh|grep -v ^#|grep -v mk_|awk '{print $4}'|sort -r)
						# NOTE that if there are multiple destinations, success depends on:
						#	- barton40 being last in the server list above (sort -r)
						#	- archiving being done after sending successfully to barton40
						#	- the same destination directory being used for all
						#	  destination servers, and the same remote file name

tail -1 $FILELIST|read LOCALFLE
[ -f $LOCALDIR/$LOCALFLE ] || exit		# file may have been renamed after a failed 'scp'

fuser $LOCALDIR/$LOCALFLE|read INUSE
[ -n "$INUSE" ] && exit				# file is present but in use, try later

#check_duplicate				# commented out - allow duplicates to process

cd $LOCALDIR
while [ $# -gt 0 ]				# send to all destinations before preserving history and archiving
do
	REMOTESERVER=$1				# first visibe parameter
	scp -p $LOCALFLE $REMOTESERVER:$REMOTEDIR/$REMOTEFILENAME 2>/dev/null
	RC=$?
	if [ $RC -ne 0 ]
	then
		echo "Transfer of $LOCALFLE to $REMOTESERVER:$REMOTEDIR/$REMOTEFILENAME failed RC=$RC"|
			mailx -s "$LOCALFLE to $REMOTESERVER:$REMOTEDIR/$REMOTEFILENAME failure" mvv	# dmsdwprod
		build_ts
		mv $LOCALFLE $LOCALFLE.$TS	# make sure other lines in cronfifteen do not process the file
						# until the cause of failure is found
		exit 2
	fi
	shift					# drop first parameter, second (if any) is now first
done

cksum $LOCALFLE|read CKSUM SIZE REST		# third token from cksum not used
echo "$CKSUM $SIZE on $(date '+%Y%m%d at %H%M')">>$HISTDIR/$LOCALFLE	# maintain history anyway
ls -li $LOCALDIR/$LOCALFLE>>$OWNERS/$LOCALFLE   # file listing before archiving
archive_file
