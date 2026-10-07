#!/bin/ksh

exec 2>/tmp/$(basename $0 .ksh).trace.$(date +%Y%m%d_%H%M)
set -x

trap 'rm -f /tmp/$$*' EXIT				# cleanup

CONTROL=/ftp/common/control/$(basename $0 .ksh)		# name of the control file
LANDING=$(grep LANDING $CONTROL|awk -F= '{print $2}')	# extract variables
TARGET=$(grep TARGET $CONTROL|awk -F= '{print $2}')	
ARCHIVE=$(grep ARCHIVE $CONTROL|awk -F= '{print $2}')	
set -- $(grep NOTEXPECTED $CONTROL|awk -F= '{print $2,$3,$4,$5,$6}')	
NOTEXPECTDIR=$1
shift

cd $LANDING						# input files are here (if any)
RENAMED=0						# count renamed files (may be used later)

for OLDNAME in *					# rename files whose names contain spaces
do
	echo "$OLDNAME"|sed -e 's/_  *_/_/g' -e 's/_  */_/g' -e 's/  *_/_/g' -e 's/ /_/g'|read NEWNAME
	if [ "$OLDNAME" != "$NEWNAME" ]
	then
		mv "$OLDNAME" $NEWNAME
		RENAMED=$((RENAMED+1))
		echo "Renamed \"$OLDNAME\" to \"$NEWNAME\"">>/tmp/$$.renames
	fi
done

ls|awk '{printf "%s %s\n",toupper($1),$1}'>/tmp/$$	# create a temporary file containing two columns:
							# the file name in UPPER CASE (1), and the original name (2)

grep -v "^#" $CONTROL|awk '{print toupper($1)}'|while read AGCY
do							# process the files by Agency Name
	grep _${AGCY}_ /tmp/$$|grep ^SANDY|egrep -q "CSV |XLS |XLSX " || continue
	grep _${AGCY}_ /tmp/$$|grep ^SANDY|egrep "CSV |XLS |XLSX "|awk '{print $2}'|while read NAME
	do
		PROPERAGCY=$(echo $NAME|awk -F_ '{print $2}')
		mv "$NAME" ../$PROPERAGCY
		echo "$NAME">>/tmp/$$.processed
	done
done

if [ -f $LANDING/* ]					# email list of files left in the landing
then							# directory that do not match design criteria
	echo "Files left in $LANDING:">>/tmp/$$.sendmail
	ls -l $LANDING|grep -v total>>/tmp/$$.sendmail
	for PART in $*
	do
		if [ -f $LANDING/*$PART* ]		# recognized agencies
		then
			mv $LANDING/*$PART* $NOTEXPECTDIR	# move them out of the way
			ls -l $NOTEXPECTDIR/*$PART*>>/tmp/$$.sendmail
		fi
	done
	if [ -f $LANDING/* ]				# other files left in the landing directory
	then
		echo "\nUnrecognized other files in $LANDING:">>/tmp/$$.sendmail
		ls -l $LANDING|grep -v total>>/tmp/$$.sendmail
		mv $LANDING/* $NOTEXPECTDIR
	fi
fi
[ -s /tmp/$$.renames ] && cat /tmp/$$.renames>>/tmp/$$.sendmail
[ -s /tmp/$$.sendmail ] && cat /tmp/$$.sendmail|mailx -s "Messages from sandy processing" -c sandy dmsdwprod
[ -s /tmp/$$.processed ] && cat /tmp/$$.processed|mailx -s "Sandy files processed on $(date +%m/%d/%Y)" -c dmsdwprod sandy
sleep 1
