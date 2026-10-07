#!/bin/ksh
cd ~/.ssh
ls -l known_hosts
mv known_hosts known_hosts.rebuild
egrep -v "costello|conover|ssh-dhs" known_hosts.rebuild|
	awk '{print $1}'|awk -F, '{print $1}'|sort -u|while read HOSTNAME
do
	ssh $HOSTNAME
	echo
done
exit
