#!/bin/ksh
#
#	called from oi-orca701-h3-e to timestamp and process the lists
#	it is started from oi-orca701-h3-e only when the 'present' list is not empty
#
exec 2>/tmp/$(basename $0 .ksh).trace.$(date +%Y%m%d_%H%M)
set -x
TS=$1
shift
CONTROL=/ftp/common/control/$(basename $0 .ksh)	# get script variables from here

LOCDIR=$(grep LOCDIR $CONTROL|awk '{print $2}')
GOODLOG=$(grep GOODLOG $CONTROL|awk '{print $2}')

grep ^INFORM $CONTROL|awk '{print $2}'|while read EMAIL
do
	EMAILLIST="$EMAILLIST $EMAIL"           # build list of email recepients
done

set -- $(grep ^DEST $CONTROL|awk '{print $2,$3,$4}')

cd $LOCDIR					# received files are here

MAXRC=0
while [ $# -gt 0 ]
do
	DESTSVR=$1
	DESTDIR=$2
	ARCDIR=$3
	shift 3
	scp -pq $(cat /etl/DMSECATS/ftp/forlogs/dwh_present.$TS) dsuser@$DESTSVR:$DESTDIR/ 2>/dev/null
	RC=$?
	MAXRC=$((MAXRC+RC))
done

archive_files () {
cat /etl/DMSECATS/ftp/forlogs/dwh_present.$TS|while read FILE
do
	compress $FILE
	if [ $? -eq 0 ]
	then
		mv $FILE.Z $ARCDIR/
	else
		mv $FILE $ARCDIR/
	fi
done
}

if [ $MAXRC -eq 0 ]
then
	archive_files
	echo "\nFiles received on $(echo $TS|awk '{print substr($1,5,2) "/" substr($1,7,2) "/" \
		substr($1,1,4) " at " substr($1,10,2) ":" substr($1,12,2)}')">>$GOODLOG
	pr -t -6 -w90 /etl/DMSECATS/ftp/forlogs/dwh_present.$TS>>$GOODLOG
	rm /etl/DMSECATS/ftp/forlogs/dwh_present.$TS
	rm /etl/DMSECATS/ftp/forlogs/dwh_missing.$TS
fi
