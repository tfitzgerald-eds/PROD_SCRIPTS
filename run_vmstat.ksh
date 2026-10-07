#!/bin/ksh
#
#	run every 30 minutes to collect vmstat statistics
#
TS=$(date +%Y%m%d_%H%M)
vmstat -Iw 2 10>/etl/vmstat_stats/stats_at_$TS
