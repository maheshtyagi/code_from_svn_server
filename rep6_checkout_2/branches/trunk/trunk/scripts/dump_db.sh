#!/bin/bash

#
# use this script to create a dump of a database and scp it to the ftp server
#

db="$1"

if [ -z "$db" ]; then
    echo "Usage $0 dbname"
    exit 1;
fi

dt=$(date +"%Y%m%d")
log="${db}_${dt}.log"
dmp="${db}_${dt}.DMP"

cmd="exp $db/$db FILE=${dmp} FULL=N log=$log OWNER='$db' GRANTS=Y COMPRESS=Y STATISTICS=NONE CONSISTENT=Y"

echo
echo "Command: $cmd"
echo
echo -n "Execute Command? [y//n](n): "
read answ
case "$answ" in
    y*|Y*) : continue;;
    *) echo "Exiting..." ; exit;
esac

echo
echo " + $cmd"
$cmd

cmd="gzip -9 $dmp"
echo
echo " + $cmd"
$cmd
dmp="$dmp.gz"

cmd="scp $dmp azetra@dev-ftp.us.kronos.com:/export/data/dev-ftp/azetra/keep1week"
cmd2="scp $log azetra@dev-ftp.us.kronos.com:/export/data/dev-ftp/azetra/keep1week"
echo
echo "Command: $cmd"
echo
echo -n "Execute Command? [y/n](n): "
read answ
case "$answ" in
    y*|Y*) : continue;;
    *) echo "Exiting..." ; exit;
esac

echo
echo " + $cmd"
$cmd
echo " + $cmd2"
$cmd2

echo "
    ==================== Cut/Paste this into email ====================

The dump of DB $db can be retrieved from here:

    azetra@dev-ftp.us.kronos.com://export/data/dev-ftp/azetra/keep1week/$dmp
    azetra@dev-ftp.us.kronos.com://export/data/dev-ftp/azetra/keep1week/$log

    ftp://dev-ftp.deploy.com/keep1week/$dmp
    ftp://dev-ftp.deploy.com/keep1week/$log

 === and remove old stuff left arround ========================
"
ls -tl *.log *.DMP *.DMP.gz
