 #!/bin/sh

 # If ANTRUN_NOHUP environment variable is set to true/yes/nohup, run the
 # executable prefixed with "nohup" making it immune to logging out.
 case $ANTRUN_NOHUP in
    true|yes|nohup) ANTRUN_NOHUP=nohup ;;
    *) unset ANTRUN_NOHUP ;;
 esac

 # JBOSS_HOME environment variable must be set
 if [ -n "$JBOSS_HOME" ]
 then
    cd "$JBOSS_HOME"
    $ANTRUN_NOHUP $@ 1>$JBOSS_HOME/jboss.out 2>$JBOSS_HOME/jboss.error &
    exit 0
 else
    echo "$0: ERROR: variable JBOSS_HOME must be set!"
    exit 1
 fi
