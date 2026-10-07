#!/bin/ksh
case $# in
	1) ;;
	*) echo Must pass file name to locate
	   exit;;
esac
HOST=$(hostname -s)
[ $HOST = abbott02 ] && WHERE=/ftp || WHERE=/etl
find $WHERE -type f -name \*$1\* -exec ls -l {} \; 2>/dev/null|grep -v history|grep -v implement
