#!/bin/ksh

# do not start another copy of cronfifteen if the script is running
NOW=$(date +%Y%m%d_%H%M)
COMMAND=cronfifteen.ksh
exec 2>/tmp/$(basename $0 .ksh).trace.$NOW
set -x

RUNNING=$(ps -ef|grep -w $COMMAND|egrep -v "grep|vi|view|more|cat"|wc -l)
if [ $RUNNING -gt 0 ]
then
	ps -ef|grep -w $COMMAND|grep -v grep>/tmp/$COMMAND.abort.$NOW
	exit
fi

/etl/common/scripts/cronfifteen.ksh 1>/etl/common/scripts/logs/cronfifteen.log 2>&1
