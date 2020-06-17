#!/bin/sh 

REPOS="$1"
TXN="$2"

SVNLOOK=/usr/bin/svnlook
ICONV=/usr/bin/iconv
PERL=/usr/bin/perl
PARSEXML=parse-xml.pl

# Prepairing to set the IFS (Internal Field Separator) so "for CHANGE in ..." will iterate
# over lines instead of words
OIFS="${IFS}"
NIFS=$'\n'

# Make sure en_US contents are properly spelled check before 
# commiting them into the subversion source control system.

IFS="${NIFS}"

for CHANGE in $($SVNLOOK changed -t "$TXN" "$REPOS"); do
    IFS="${OIFS}"
    # Skip change if first character is "D" (we dont care about checking deleted files)
    if [ "${CHANGE:0:1}" == "D" ]; then
        continue
    fi

    # Skip change if it is a directory (directories don't have encoding)
    if [ "${CHANGE:(-1)}" == "/" ]; then
        continue
    fi

    # Extract file repository path (remove first 4 characters)
    FILEPATH=${CHANGE:4:(${#CHANGE}-4)}

    # Ignore files that starts with "." like ".classpath"
    IFS="//" # Change seperator to "/" so we can find the file in the file path
    for SPLIT in $FILEPATH
    do
        FILE=$SPLIT
    done
    if [ "${FILE:0:1}" == "." ]; then
        continue
    fi
    IFS="${OIFS}" # Reset Internal Field Seperator
      
    echo  $FILEPATH  | egrep "DisplaySet|DisplayText|MailTemplate|Answer|Question" >/dev/null
    if [ "$?" -eq "0" ];then

        $SVNLOOK cat -t "$TXN" "$REPOS" "$FILEPATH" | $PERL ${PARSEXML}
        # If the parse exited with a non-zero value (error)  then reject commit.
        if [ "${PIPESTATUS[1]}" != "0" ]; then
            echo "Spell checker issue..Please fix the spelling before committing"
            exit 1
        fi
    
    fi

    IFS="${NIFS}"
done

IFS="${OIFS}"

# All checks passed, so allow the commit.
exit 0

