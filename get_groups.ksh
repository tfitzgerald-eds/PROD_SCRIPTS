#!/bin/ksh
grep -w $1$ /ftp/common/control/archives_sweep|awk '{print $1}'|sort -u>/tmp/${1}_groups
cd /ftp/archive_logs
cat /tmp/${1}_groups|while read GROUP
do
	grep $GROUP /tmp/${1}_groups archive_*|awk '
	NF<2 {next}
	{N=index($0,"/")
	if (N==0)
	  next
	print substr($0,N)}'|awk -F/ '{print $NF}'
done>/tmp/${1}_files
sort -u /tmp/${1}_files|sed 's!/ftp/!!'>/tmp/${1}_unique_a02
