#!/bin/ksh

exec 2>/tmp/$(basename $0 .ksh).trace
set -x

CONTROL=/ftp/common/control/$(basename $0 .ksh)

tput clear
echo "\n\n\n\n\n\n\n\n\n\n\tReply 'q' to any prompt to terminate this script\n"

while echo "\tEnter new client two character code: \c"
do
	read CODE
	[ $CODE = q ] && exit
	if [ ${#CODE} -ne 2 ]
	then
		echo "\t$CODE is not 2 characters long"
	else
		grep CLIENT $CONTROL|grep -wq $CODE
		if [ $? -eq 0 ]
		then
			echo "\t$CODE already exists"
		else
			break
		fi
	fi
done
lsuser nj${CODE}tr1 1>/dev/null 2>&1
#echo						# force RC 0, comment out when done
if [ $? -ne 0 ]
then
	echo "\n\tID nj${CODE}tr1 does not exist yet on $(hostname -s)"
	exit
fi
while echo "\tEnter name for $CODE: \c"
do
	read NAME
	[ $NAME = q ] && exit
	if [ -z "$NAME" ]
	then
		echo "\tThe name may not be blank"
	else
		break
	fi
done
echo "#CLIENT $CODE $NAME">>$CONTROL
echo $CODE>/tmp/CODE
scp -p /tmp/CODE njsptr1@oi-orca701-h3-e:/stg/njsp_control/
scp -p /tmp/CODE njsptr1@oi-orca705-m3-s:/stg/njsp_control/
rm /tmp/CODE
mkdir -p /ftp/nj${CODE}tr1/ftp
cd /ftp/nj${CODE}tr1
mkdir archives duplicates rejects

echo "\nDirectories for processing files from $NAME have been created"
echo "Provide nj${CODE}tr1 credentials to DOT group for requesting DataMotion account"
echo "\nProceed with running tr1_new_client.ksh on orca servers with root credentials"
