#!/bin/sh

#
#Script to apply BOM 
#Created By Amit Kalia ,Date:-32/05/2011
#

dir=$1
bomFileName=$2
sleepTime=240
ant="/vol/app/atao/apache-ant-1.7.1/bin/ant"
nohup="/usr/bin/nohup"
mv="/bin/mv"

logFile="applyBOM.log"
exec &>$logFile

#JBOSS configuration:-
broadcastAddress="0.0.0.0"
clusterGroup="it-prodmgmt"
udpAddress="237.0.0.107"

#Error condaitions
ERR_PRIMARY_BACKUP=1
ERR_PRIMARY_INSTALL=2
ERR_PRIMARY_RESTOR=3

#/vol/app/atao/BOMReleases/8.7/antBomInstallLocalSettings.properties
#$antBomInstallLocalSettingsProp="/vol/app/atao/BOMReleases/8.7/antBomInstallLocalSettings.properties"

#The below variable needs to be changed if BOM needs to 
#be applied on different environment.

unzip="/vol/app/oracle/product/10.2.0/bin/unzip"
cp="/bin/cp"

[ -d $dir ] && cd $dir
$mv "$bomFileName" ../
[ -f $unzip ] && $unzip ../"$bomFileName"

$cp "/vol/app/atao/BOMReleases/8.7/antBomInstallLocalSettings.properties" .

#Shutdown Jboss
echo "Shutting down Jboss....sleeping for $sleepTime"
$JBOSS_HOME/bin/shutdown.sh -S -u admin -p admin
sleep $sleepTime

echo "Running Primary Backup"

$ant -f BOMInstall.xml primaryBackup

if [ "$?" -eq "0" ];then
    echo "Primary Backup Succesfull"

else
    echo "Primary Backup failed..restaring jboss and exiting"
    $nohup $JBOSS_HOME/bin/run.sh -b${broadcastAddress} -g${clusterGroup} -u${udpAddress} >1>/vol/app/atao/jboss43/jboss.out 2>/vol/app/atao/jboss43/jboss.error &
    sleep $sleepTime
    exit $ERR_PRIMARY_BACKUP 
fi

echo "Running Primary Install"
$ant -f BOMInstall.xml primaryInstall

if [ "$?" -eq "0" ];then
    echo "Primary Install Succesfull"
else
    echo "Primary Install failed..Continuing with Restore"
    $ant -f BOMInstall.xml primaryRestore
    if [ "$?" -eq "0" ];then
        echo "Primary Restore is successful"
    else
        echo "Primary Restore has Failed"
        echo "Restarting JBOSS 4.3"
        $nohup $JBOSS_HOME/bin/run.sh -b${broadcastAddress} -g${clusterGroup} -u${udpAddress} >1>/vol/app/atao/jboss43/jboss.out 2>/vol/app/atao/jboss43/jboss.error &
        exit $ERR_PRIMARY_RESTORE 
    fi
fi

echo "Restarting JBOSS 4.3"
$nohup $JBOSS_HOME/bin/run.sh -b${broadcastAddress} -g${clusterGroup} -u${udpAddress} >1>/vol/app/atao/jboss43/jboss.out 2>/vol/app/atao/jboss43/jboss.error &
