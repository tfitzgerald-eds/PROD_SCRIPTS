#!/bin/ksh
exec 1>/tmp/999_extract
cd /ftp/archive_logs_ootw
cat /tmp/999_only_abbott02|while read FILE
do
	grep -l $FILE list*|read LOG
	echo $LOG $FILE
done
