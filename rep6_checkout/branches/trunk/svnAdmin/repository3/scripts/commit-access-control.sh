#!/bin/bash

export PATH=/usr/kerberos/bin:/usr/local/bin:/bin:/usr/bin:/usr/X11R6/bin
scriptDir=/svnroot/repository3/scripts
branchLockListCheckout=$scriptDir/branchlock.list
branchLockListClean=$scriptDir/branchlock.list.clean
logfile=$scriptDir/Repo_log.txt
txnRaw=$scriptDir/txn_raw.txt
txnFullPath=$scriptDir/txn_full_path.txt
txnBranch=$scriptDir/txn_branch.txt

SVNLOOK=/usr/bin/svnlook
REPOS=$1
TXN=$2

if [ ! -d $scriptDir ] ; then
    echo "WARNING $scriptDir is not a directory" | tee -a $logfile
else
    if [ ! -w $scriptDir ] ; then
        echo "ERROR $scriptDir is not writable"  | tee -a $logfile
    fi
fi

# Clean up any leftover previous workfiles
for pwf in $txnRaw $txnFullPath $txnBranch ; do
    if [ -f $pwf ] ; then
        rm -f $pwf
        if [ -f $pwf ] ; then
            echo "ERROR: unable to delete previous working file $pwf - please contact RE"
        fi
    fi
done

$SVNLOOK changed -t "$TXN" "$REPOS" > $txnRaw

if [ ! -f $txnRaw ] ; then
    echo "ERROR: $txnRaw not found"                >> $logfile
    echo "    svnlook changed -t for $TXN  $REPOS" >> $logfile
    $SVNLOOK changed -t "$TXN" "$REPOS"            >> $logfile
    echo ""                                        >> $logfile
    exit 1
fi

head -1 < $txnRaw | sed -e s#"^_*[A-Z]* *"## > $txnFullPath
if [ $( awk -F/ '{print $1}' < $txnFullPath ) = trunk ] ; then
    cat $txnFullPath > $txnBranch
else
    if [ $( awk -F/ '{print $1}' < $txnFullPath ) = branches ] ; then
    sed -e s#"^branches\/"## < $txnFullPath > $txnBranch
    # This part not working right, and cluttering the logs - commenting for now
    #else
    #    echo "WARNING: checkin not in trunk or branch " >> $logfile
    #    echo "    svnlook changed -t for $TXN  $REPOS"  >> $logfile
    #    $SVNLOOK changed -t "$TXN" "$REPOS"             >> $logfile
    #    echo ""                                         >> $logfile
    fi
fi
branchname=`cat $txnBranch | tail -1 | awk -F/ '{print $1}'`
chmod 777 $txnRaw $txnFullPath $txnBranch > /dev/null 2>&1

committer=`$SVNLOOK author -t "$TXN" "$REPOS"`
echo >> $logfile
echo -n "==> user $committer attempting checkin to branch ${branchname} at " >> $logfile
date >> $logfile


# Strip any DOS-style line engings from branch lock list (^M endings break the regex matching below)
# Have to make a copy, otherwise the auto-update cron reports a conflict
cat $branchLockListCheckout | dos2unix > $branchLockListClean 2> /dev/null
chmod 777 $branchLockListClean > /dev/null 2>&1

# Look for a (non-commented) entry in the lock list
if [ $( grep -v '^#' < $branchLockListClean | awk '{print $1}' | grep "^$branchname$" | wc -l ) -ne 0 ] ; then
    branchHasRestrictions=yes
    auth_committers=$(grep -v '^#' < $branchLockListClean  | grep "^$branchname[ $]" | sed -e s/"^$branchname"//)
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
	    if [ $( grep 'atao/test'           < $txnBranch | wc -l ) -eq 1 ] || \
	       [ $( grep 'atao/functionalTest' < $txnBranch | wc -l ) -eq 1 ] ; then
	        if [ $( grep -v 'atao/test' < $txnBranch | wc -l ) -ne 0 ] || [ $( grep -v 'atao/functionalTest' < $txnBranch | wc -l ) -ne 0 ] ; then
	            echo "   You are not authorized to commit into paths other than atao/test, atao/functionalTests"
	            echo "   disallowing this commit transaction."   
	            exit 1
	        else
	            echo "   changes under  atao/test and atao/functionalTest always permitted"  >> $logfile
		    $SVNLOOK changed -t "$TXN" "$REPOS" >> $logfile
		    exit 0
	        fi
	    fi
            echo "$branchname is restricted - checkins are only permitted by the following users:" | tee -a $logfile
            echo "    $auth_committers"                                                            | tee -a $logfile
        fi
        echo
        exit 1
    fi
fi



