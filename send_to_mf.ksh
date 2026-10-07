#!/bin/ksh
exec 2>/tmp/$(basename $0 .ksh).trace
set -x
exit
