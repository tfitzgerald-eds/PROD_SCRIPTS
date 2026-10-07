#!/bin/ksh
#
#	This script is the front end to loading CRASH data files for the
#	NJ TR1 project.  It performs validation before sending the files to
#	the DataBase server where they get loaded into table ARD_XML_IMPORT_EDT
#	via SQLLDR.  Once all the files have been copied to the destination server
#	script /stg/njsp_scripts/load_njsp_data.ksh is invoked via ssh.
#	Most script variables are extracted at run time from the CONTROL file.
#
RUNTYPE=P				# default is production run
set -- `getopt t $*` 2>/dev/null
# check result of parsing
if [ $? != 0 ]
then
	echo Invalid option found
        exit 1
fi
while :
do
        case $1 in
        	-t) RUNTYPE=T;shift;;	# test run, can only be set when running manually
        	--) shift;break;;
        esac
done

exec 2>/tmp/$(basename $0 .ksh).$1.trace.$(date +%Y%m%d_%H%M%S)
set -x

>/tmp/rejects.$$			# create temporary empty file
trap 'rm -f /tmp/rejects.$$' EXIT	# cleanup

CODE=$1                                 # i.e. - sp, en
shift

# set up environment
CONTROL=/ftp/common/control/$(basename $0 .ksh)
WORKDIR=/ftp/nj${CODE}tr1/ftp
ARCHIVEDIR=/ftp/nj${CODE}tr1/archives
REJECTS=/ftp/nj${CODE}tr1/rejects
DUPLICATES=/ftp/nj${CODE}tr1/duplicates
INFORM=$(grep ^INFORM= $CONTROL|awk -F=	'{print	$2}')
if [ $RUNTYPE = P ]
then
	DEST=$(grep ^PDEST= $CONTROL|awk -F= '{print $2}'|
		sed -e "s/njsptr1/nj${CODE}tr1/" -e "s/NJSP/nj${CODE}tr1/")
	EXECMD="$(grep ^PEXEC= $CONTROL|awk -F= '{print $2}'|sed 's/:/ /g') $CODE"
else
	DEST=$(grep ^TDEST= $CONTROL|awk -F= '{print $2}'|
		sed -e "s/njsptr1/nj${CODE}tr1/" -e "s/NJSP/nj${CODE}tr1/")
	EXECMD="$(grep ^TEXEC= $CONTROL|awk -F= '{print $2}'|sed 's/:/ /g') $CODE"
fi

case $# in				# create subset of files to process
	0) TGT="";;			# default is to process all files in work directory
	1) TGT=$1;;			# can only be done from the command line
	2) TGT=$(echo $*|awk '{printf "%-4s%2s\n",$1,$2}');;
	3) TGT=$(echo $*|awk '{printf "%-4s%2s %s\n",$1,$2,$3}');;
esac

cd $ARCHIVEDIR				# next three lines build a list of files names aready processed
ls *xml>/tmp/$(basename $0 .ksh)_processed
cd /ftp/archive_logs			# in order to reject and count duplicates
grep /ftp/nj${CODE}tr1/archives *|grep -v :/|awk '/xml/ {print $NF}'>>/tmp/$(basename $0 .ksh)_processed

cd $WORKDIR
if [ -z	"$TGT" ]			# target list is empty, process everything
then
	XMLLIST=$(ls *xml>/tmp/$(basename $0 .ksh)_list)
else
	XMLLIST=$(ls -l	*xml|grep "$TGT"|awk '{print $NF}'|grep	-v total>/tmp/$(basename $0 .ksh)_list)
fi

COUNTB=0	COUNTG=0	COUNTD=0
if [ ! -s *xml ]				# no xml files
then
	echo "\nNo XML files present.\n"|mailx -s "Results of nj${CODE}tr1 load $(date)" $INFORM
	exit
fi

send_files () {
set -x
cat /tmp/$(basename $0 .ksh)_list|wc -l|read XMLCOUNT
if [ $COUNTG -gt 0 ]
then
	scp -p * $DEST 1>/dev/null 2>&1
	RC=$?
else
	[ $COUNTB -gt 0 ] && echo "No nj${CODE}tr1 TR1 files left to send"|mailx -s "No files" $INFORM
	return
fi
if [ $RC -ne 0 ]
then
	ls $XMLFILE $PDFFILE>>/tmp/rejects.$$
	mv * $REJECTS/
#	COUNTB=$((COUNTB+XMLCOUNT))
else
	[ $RUNTYPE = P ] && rm -f $(ls -l|awk '$2==2 {print $NF}')
						# keep files if not production run but
fi						# only delete files that have 2 links
						# just in case more files arrived while
						# this script was running
}

for XMLFILE in $(cat /tmp/$(basename $0 .ksh)_list)
do
	PDFFILE=$(echo $XMLFILE|sed 's/xml/pdf/')
	#  if PDF file is zero length and load service is NOT 'en'
	if [ ! -s $PDFFILE && $CODE != 'en' ]   # sml 3-18-19: no PDF files expected for "en"
	then
		mv -f $XMLFILE $REJECTS/
		echo "No matching .pdf file for	$XMLFILE">>/tmp/njsp_xml_no_pdf
		COUNTB=$((COUNTB+1))
		continue
	else
		PDFFILE=""			# sml 3-18-19: no PDF
	fi
	grep -q $XMLFILE /tmp/$(basename $0 .ksh)_processed
	if [ $? -eq 0 ]
	then
		echo $XMLFILE>>/tmp/njsp_xml_dupes
		mv -f  $XMLFILE $PDFFILE $DUPLICATES/
		COUNTD=$((COUNTD+1))
		continue
	fi
	grep TRANSFER_CONTROL $XMLFILE|wc -l|read TAGCNT
	if [ $TAGCNT -ne 2 ]
	then
		mv $XMLFILE $PDFFILE $REJECTS
		echo "Incomplete XML file $XMLFILE">>/tmp/njsp_xml_incomplete
		COUNTB=$((COUNTB+1))
		continue
	fi
	COUNTG=$((COUNTG+1))
	[ $RUNTYPE = P ] && ln -f $XMLFILE $PDFFILE $ARCHIVEDIR/
						# do not archive, unless production run
done

send_files					# send files present in the work directory

if [ $COUNTB -gt 0 ]
then
	(echo "\n$COUNTB nj${CODE}tr1 TR1 failures";cat /tmp/rejects.$$)|
		mailx -s "Errors encountered by nj${CODE}tr1 TR1 process" $INFORM
fi

PATH=$PATH:/home/dsuser/mikev/bin
COUNTGC=$(pc $COUNTG)				# format numbers with commas
COUNTBC=$(pc $COUNTB)				# when appropriate
COUNTDC=$(pc $COUNTD)
ssh $EXECMD $COUNTGC $COUNTBC $COUNTDC
