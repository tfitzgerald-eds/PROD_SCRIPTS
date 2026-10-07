#!/bin/ksh
########################################################
# Written By: Nikki Fordyce
# Date: 06/03/2024
# Purpose: To Test SSH Passwordless Functions
########################################################
#
# /ftp/common/control/servers.txt - list all active AIX servers 
#
# if ssh -o BatchMode=yes $host uptime - To test passwordless and fingerprint connectivity

for host in $(< /ftp/common/control/servers.txt) 
do
  echo testing $host
  if ssh -o BatchMode=yes $host uptime
  then echo host $host OK
  else echo host $host DOWN
  fi
done > result.log

mail -s "SSH Report" "OIT-EnterpriseDataServices@tech.nj.gov, dmsdsadmin@tech.nj.gov" <result.log
rm -fr /home/dsuser/workdir/result.log
