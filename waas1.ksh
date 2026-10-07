#!/bin/ksh
#
#       Script runs once daily loking for billing file
#       exits if not present
#
#       Runs from cron daily at 8:45 ahead of the 9:00 DataStage
#       job on barton40
#
exec 2>/tmp/$(basename $0 .ksh).trace
set -x

cd /ftp/DMSCARS/waas
if [ -s waas.test.csv ]
then
	FILE=$(ls waas.test.csv)
	else
		exit
		fi

		scp -pq $FILE barton40:/etl/DMSCARS/ftp/waas.test.csv 2>/dev/null
		RC=$?

		if [ $RC -eq 0 ]
		then
			compress $FILE
				if [ $? -eq 0 ]
					then
							mv $FILE.Z ../archives
								else
										mv $FILE ../archives
											fi
											fi
