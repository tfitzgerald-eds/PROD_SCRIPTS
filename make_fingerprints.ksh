#!/bin/ksh
if [ $(id -u) -ne 0 ]
then
	echo "This script must be run with 'root' credentials"
	exit
fi
cd /ftp/mikev
TTY=$(tty)
cd /home
ls -1 */.ssh/known_hosts|awk -F/ '{print $1}'|while read USER
do
	lsuser -a gecos $USER|awk '{GCOL=index($0,"=");print substr($0,GCOL+1)}'|read GECOS

	echo "\nRebuild connections for $USER: $GECOS? (y/n) \c"
	read ANS<$TTY
	case $ANS in
		[yY]*) echo Processing $USER;;
		    *) echo Skipping $USER;continue;;
	esac
done
