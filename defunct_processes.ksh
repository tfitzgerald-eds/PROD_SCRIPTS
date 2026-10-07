#!/bin/ksh
########################################################
# Written By: Nikki Fordyce
# Date: 08/31/2021
# Purpose: To report defunct processes
########################################################

########################################################
# A defunct process, also known as a zombie, is simply a process that is no longer running, but remains in the process table to allow the parent to collect its exit status                   # information before removing it from the process table.
# Because a zombie is no longer running, it does not use any system resources such as CPU or disk,
# and it only uses a small amount of memory for storing the exit status and other process related information in the slot where it resides in the process table.
########################################################

# To display the defunct processes in a text file and send the text file via email.

ps -ef | grep defunct > defunct_processes.txt
mail -s "Abbott02 - defunct processes" "dmsdsadmin@tech.nj.gov" "OIT-dmsdwteam@tech.nj.gov" < defunct_processes.txt
cd /home/dsuser/workdir/
rm -fr defunct_processes.txt
