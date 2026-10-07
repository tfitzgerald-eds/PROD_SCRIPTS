#!/bin/ksh
cd /ftp/archive_logs
awk '	{SUM=SUM+$6}
END	{printf "%f\n",SUM}' *
