#!/bin/ksh
#
#	Run once daily to upload sandy files (if any)
#
exec 2>/tmp/$(basename $0 .ksh).trace.$(date +%Y%m%d_%H%M)
set -x

trap 'rm -f /tmp/$$*' EXIT				# cleanup

CONTROL=/ftp/common/control/$(basename $0 .ksh)		# name of the control file
LANDING=$(grep LANDING $CONTROL|awk -F= '{print $2}')	# extract variables
TARGET=$(grep TARGET $CONTROL|awk -F= '{print $2}')	
ARCHIVE=$(grep ARCHIVE $CONTROL|awk -F= '{print $2}')	
DMDEST=$(grep DMDEST $CONTROL|awk -F= '{print $2}')	
SENDTO=$(grep TOSERVER $CONTROL|awk -F= '{print $2}')	# list of destinations to send files to

TS=$(date +%Y%m%d)					# timestamp in YYYYMMDD format

for AGCY in $(grep ^[A-Z] $CONTROL|grep -v '=')		# skip variable definition  statements
do
	cd $LANDING/../$AGCY
	[ -f * ] || continue				# check for files in each agency's directory
	for FILE in *
	do
		for SERVER in $SENDTO
		do
			scp -p $FILE $SERVER		# send original file to all destinations
		done
		echo $FILE $TS|awk '{split($1,ARR,".")	# rename the file to include the timestamp
				     print ARR[1] "_" $2,ARR[2]}'|read BASENAME EXT
		mv $FILE $BASENAME.$EXT
#		cp -p $BASENAME.$EXT $TARGET		# copy to the directory from where
							# it can be picked up by DataMotion
		compress $BASENAME.$EXT			# compress it (if compressible)
		mv $BASENAME.$EXT* $ARCHIVE		# archive the result (may or may not have .Z suffix)
	done
done

exit							# change 17/04/2015 to prevent sending anything to DataMotion
#####################################################################################################################
cd $TARGET
[ -f * ] || exit					# stop if nothing found

for FILE in *
do
	echo "$FILE"|awk '{split($1,ARR,".")
			   print ARR[1]}'|read BASENAME
	echo "|${FILE}|SANDY TRANSPARENCY AGENCY FILE OUT|||||">"$BASENAME".ctl
done

ls *ctl|wc -l|read FILECNT

#scp *ctl $DMDEST					# upload control files to the bridge

echo "Uploaded $FILECNT sandy ctl files"|mailx -s "Files to DataMotion" mvv
