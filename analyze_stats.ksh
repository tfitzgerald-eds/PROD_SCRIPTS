#!/bin/ksh
echo $(hostname)
cd /etl/vmstat_stats
ls -rt|while read STATSFILE
do
	awk 'NR==8 {printf "%s: %3d\n",FILENAME, $17}' $STATSFILE
done
