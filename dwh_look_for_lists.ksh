#!/bin/ksh
#
#	Looks for unfinished process_dwh_lists.ksh jobs and tries to finish them
#	Runs the same process that is started from oi-orca701-h3-e
#
exec 2>/tmp/$(basename $0 .ksh).trace.$(date +%Y%m%d_%H%M)
set -x

ps -ef|grep process_dwh_lists.ksh|grep -v grep|wc  -l|read COUNT
[ $COUNT -gt 0 ] && exit                # previous iteration did not finish

ps -ef|grep dwh_look_for_lists.ksh|grep -v grep|wc  -l|read COUNT
[ $COUNT -gt 1 ] && exit                # previous iteration did not finish

cd /etl/DMSECATS/ftp/forlogs
ls -l dwh_present*|
	awk '$5>0 {split($NF,A,".")
		   print A[2]}'|read TS
[ -n "$TS" ] && /home/dsuser/workdir/process_dwh_lists.ksh $TS

ls -l dwh_present*|
	awk '$5==0 {split($NF,A,".")
		   print A[2]}'|while read TS
do
	rm *$TS
done
