#!/bin/bash

export PATH=/usr/kerberos/bin:/usr/local/bin:/bin:/usr/bin:/usr/X11R6/bin
scriptDir=/svnroot/repository4/scripts
logfile=$scriptDir/Repo_log.txt
branchLockList=$scriptDir/branchlock.list

SVNLOOK=/usr/bin/svnlook
REPOS=$1
TXN=$2
$SVNLOOK changed -t "$TXN" "$REPOS" | grep "[A-Z] *branches\/" | sed -e s#"^[A-Z] *branches\/"##  >> $scriptDir/temp_file.txt
branchname=`cat $scriptDir/temp_file.txt | tail -1 | awk -F/ '{print $1}'`
rm -rf $scriptDir/temp_file.txt
if [ "${branchname}" = "" ]
then
   branchname=trunk
fi

committer=`$SVNLOOK author -t "$TXN" "$REPOS"`
echo >> $logfile
echo -n "==> user $committer attempting checkin to branch ${branchname} at " >> $logfile
date >> $logfile

# Look for a (non-commented) entry in the lock list
if [ $( grep -v '^#' < $branchLockList | awk '{print $1}' | grep "^$branchname$" | wc -l ) -ne 0 ] ; then
    branchHasRestrictions=yes
    auth_committers=$(grep -v '^#' < $branchLockList  | grep "^$branchname[ $]" | sed -e s/"^$branchname"//)
else
    branchHasRestrictions=no
    auth_committers=""
    $SVNLOOK changed -t "$TXN" "$REPOS" >> $logfile
fi

# If this branch is in the lock list, check to see if this user is authorized
if [ $branchHasRestrictions = "yes" ] ; then
    # If user is authorized, log the commit
    if [ $( echo "$auth_committers" | grep $committer | wc -l ) -eq 1 ] ; then
        echo "   $committer is authorized"  >> $logfile
        $SVNLOOK changed -t "$TXN" "$REPOS" >> $logfile
    # If this user is not authorized, explain why
    else
        echo
        # If there are no authorized users, tell user branch is completely locked
        if [ -z "$auth_committers" ] ; then
            echo "Branch $branchname is locked - checkins not allowed" | tee -a $logfile
        # If there are any authorized users, let this user know
        else
            echo "$branchname is restricted - checkins are only permitted by the following users:" | tee -a $logfile
            echo "    $auth_committers"                                                                   | tee -a $logfile
        fi
        echo
        exit 1
    fi
fi



