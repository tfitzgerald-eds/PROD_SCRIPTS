#!/bin/ksh
########################################################
# Written By: Nikki Fordyce
# Date: 07/18/2019
# Purpose: To see what keys are connecting to the LPAR 
########################################################

#Go to .ssh directory

cd /home/dsuser/.ssh

#To display the Hostname, IP Address, and Key Type in a txt file

awk '{print $1" "$2}' known_hosts >> known_hosts_keys.txt

#To mail output

mail -s "verify_known_hosts_keys" "Nikki.Fordyce@tech.nj.gov" </home/dsuser/.ssh/known_hosts_keys.txt

#Remove the known_hosts.txt file

rm /home/dsuser/.ssh/known_hosts_keys.txt
