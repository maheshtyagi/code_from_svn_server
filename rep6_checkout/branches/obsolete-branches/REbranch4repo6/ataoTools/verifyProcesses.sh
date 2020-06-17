#!/bin/bash

set -o nounset

runDate=$(date +%Y%m%d%H%M)
processesFile=/home/qaadmin/ccwork/processes.properties

if [ -e $processesFile ] ; then
    echo "Deleting existing processes file $processesFile"
    rm -rf $processesFile
else
    echo "No previous processes file found - continuing"
fi

echo "<!-- List generated at $(date +%Y%m%d%H%M) -->" >> $processesFile

for process in coldfusion xvfb ; do
    if [ $( ps -ef | grep -i $process | grep -v grep | wc -l ) -ge 1 ] ; then
        processRunning=true
    else
        processRunning=false
    fi
    echo "${process}.running=${processRunning}" >> $processesFile
done


