#!/bin/ksh
#
#	Front end to the TR1 project.  Script looks for clents with data,
#		and starts script 'process_njsp_xml.ksh' with the respective code
#

trap 'rm -f /tmp/$$' EXIT

exec 2>/tmp/$(basename $0 .ksh).trace.$(date +%Y%m%d_%H%M%S)
set -x

CLIENTLIST=/tmp/$$
CONTROL=/ftp/common/control/$(basename $0 .ksh)
set -- $(grep ^CLIENT $CONTROL|awk '{print $2}')
echo $*>$CLIENTLIST
while :
do
	set -- $(cat $CLIENTLIST)
	[ $# -lt 1 ] && break
	echo $*>&2
	CODE=$1
	shift
	echo $*>$CLIENTLIST
	/home/dsuser/workdir/process_njsp_xml.ksh $CODE
	sleep 3
done
