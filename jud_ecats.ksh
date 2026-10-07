#!/bin/ksh
#
#	Transfer file jud_ecats.txt to production server, then archive it
#	Send email in case of failure
#

TS=$(date +%Y%m%d)				# timestamp

exec 2>/tmp/$(basename $0 .ksh).trace.$TS	# trace file
set -x

# extract variables from control file
CONTROL=/ftp/common/control/$(basename $0 .ksh)
WORKDIR=$(grep ^WORKDIR= $CONTROL|awk -F= '{print $2}')
ARCHDIR=$(grep ^ARCHDIR= $CONTROL|awk -F= '{print $2}')
DEST_V8_PROD=$(grep ^DEST_V8_PROD= $CONTROL|awk -F= '{print $2}')
DEST_V11_DEV=$(grep ^DEST_V11_DEV= $CONTROL|awk -F= '{print $2}')
DEST_V11_QA=$(grep ^DEST_V11_QA= $CONTROL|awk -F= '{print $2}')
DEST_V11_DEV_PROD=$(grep ^DEST_V11_DEV_PROD= $CONTROL|awk -F= '{print $2}')
DEST_V11_PROD=$(grep ^DEST_V11_PROD= $CONTROL|awk -F= '{print $2}')


cd $WORKDIR
[ -s jud_ecats.txt ] || exit			# exit if file is not present


# send file to 8.5 PROD destination
scp -p jud_ecats.txt $DEST_V8_PROD/ 2>/dev/null
RC=$?
if [ $RC -ne 0 ]                                 # notify of failure and exit
then
   echo "Unable to send jud_ecats.txt to $DEST_V8_PROD"|mailx -s "Unable to process jud_ecats.txt" dmsdsadmin
   exit
fi


# send file to 11.7 DEV destination
scp -p jud_ecats.txt $DEST_V11_DEV/ 2>/dev/null
RC=$?
if [ $RC -ne 0 ]                                 # notify of failure and exit
then
   echo "Unable to send jud_ecats.txt to $DEST_V11_DEV"|mailx -s "Unable to process jud_ecats.txt" dmsdsadmin
   exit
fi

# send file to 11.7 QA destination
scp -p jud_ecats.txt $DEST_V11_QA/ 2>/dev/null
RC=$?
if [ $RC -ne 0 ]                                 # notify of failure and exit 
then
   echo "Unable to send jud_ecats.txt to $DEST_V11_QA"|mailx -s "Unable to process jud_ecats.txt" dmsdsadmin
   exit
fi

# send file to 11.7 DEV_PROD destination
scp -p jud_ecats.txt $DEST_V11_DEV_PROD/ 2>/dev/null
RC=$?
if [ $RC -ne 0 ]                                # notify of failure and exit
then
   echo "Unable to send jud_ecats.txt to $DEST_V11_DEV_PROD"|mailx -s "Unable to process jud_ecats.txt" dmsdsadmin
   exit
fi

# send file to 11.7 PROD destination
scp -p jud_ecats.txt $DEST_V11_PROD/ 2>/dev/null
RC=$?
if [ $RC -ne 0 ]                               # notify of failure and exit 
then
   echo "Unable to send jud_ecats.txt to $DEST_V11_PROD"|mailx -s "Unable to process jud_ecats.txt" dmsdsadmin
   exit
fi


# archive
mv jud_ecats.txt jud_ecats.txt.$TS
compress jud_ecats.txt.$TS
mv jud_ecats.txt.$TS* $ARCHDIR
