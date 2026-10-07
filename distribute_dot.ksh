#!/bin/ksh
#
#	runs every 30 minutes to transfer files to oidstag4hie and oidstaghis and oidstesthis
#
exec 2>/tmp/$(basename $0 .ksh).trace.$(date +%Y%m%d_%H%M)
set -x
DIRECTORY=/ftp/DOTTRANSINFO/ftp/DOT_EDW_FTP_FILES
cd $DIRECTORY
PDIR=$(pwd)
if [ -d "${PDIR}" ] && [ "${PDIR}" = "${DIRECTORY}" ]; then
ls|while read FILE
do
	fuser "$FILE"|read INUSE
	[ -n "$INUSE" ] && continue                             # file is in use, skip it
	scp -p "$FILE" traninf1@oidstaghis:/etl/Projects/DOT_TRANSINFO_DEV/ftp/SourceData/DOT_EDW_FTP_FILES/
	scp -p "$FILE" traninf1@oidstag4hie:/etl/Projects/DOT_TRANSINFO_PROD/ftp/SourceData/DOT_EDW_FTP_FILES/
	compress "$FILE"
	if [ $? -eq 0 ]
	then
		mv "$FILE.Z" /ftp/archives/keep92/DMSDOT/
	else
		mv "$FILE" /ftp/archives/keep92/DMSDOT/
	fi
done
fi
