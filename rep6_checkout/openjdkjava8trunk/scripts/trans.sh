#!/bin/bash
#run from ~/trunk/atao  /home/rebuild is hard coded but could be replaced with $HOME
echo -n 'What is the Translation Designation?? ' 
read value

mDate=$(date +%Y-%m-%d -d "1 day ago")

DTE="modifiedSince="$mDate

BOOTSTRAPDIR="export.db.bootstrap.dir=\/home\/rebuild\/trunk\/db.export$value\/bootstrap\/"
LIBDIR="export.db.library.dir=\/home\/rebuild\/trunk\/db.export$value\/libraries\/"
CLIENTDIR="export.db.client.dir=\/home\/rebuild\/trunk\/db.export$value\/clientData\/"
dcnt=$(ls -1 ../$value/*Display*.csv 2> /dev/null |wc -l)
qcnt=$(ls -1 ../$value/*Question*.csv 2> /dev/null |wc -l)
mcnt=$(ls -1 ../$value/*Mail*.csv 2> /dev/null |wc -l)

PATHCSV="/home/rebuild/trunk/"$value"/"
LIBALPHA=$(sed -e '1,2d' -e 's/^Display.*//' -e 's/^Library.*//' -e 's/,.*//' -e 's/^.*Display.*//' -e '/^$/d' $PATHCSV*Display*.csv |sort -fdt, | uniq |sed -e 's/$/,/g' |tr "\n" " " |sed -e 's/, /,/g' -e 's/.$//' )
COREIS=$(expr match "$LIBALPHA" '.*core')
#Other libraries sometimes have dependencies on core so If it's in the list and not first, move it there.
if [ $COREIS -gt 4 ]; 
then
	LIBHOLD=$(echo $LIBALPHA | sed -e 's/,core//' -e 's/^/core,/')
	LIBLIST="library.list="$LIBHOLD
else
	LIBLIST="library.list="$LIBALPHA
fi

#transclient.sh - clients come from QuestionResponse and MailTemplate csv files.

if [ $qcnt -gt 0 ]; 
then
	CLIENTSQ=$(sed -e '1,2d' -e 's/,.*//' -e 's/^Client.*//' -e 's/^.*Question.*//' -e 's/^_.*//' -e '/^$/d' $PATHCSV*Question*.csv | sort -fdt, | uniq |sed -e 's/$/,/g' |tr "\n" " " |sed -e 's/, /,/g' -e 's/.$//'  )
else
	CLIENTSQ=""
fi

if [ $mcnt -gt 0 ]; 
then
	CLIENTSM=$(sed -e '1,2d' -e 's/,.*//' -e 's/^Client.*//' -e 's/^.*Mail.*//' -e 's/^_.*//' -e '/^$/d' $PATHCSV*Mail*.csv | sort -fdt, | uniq |sed -e 's/$/,/g' |tr "\n" " " |sed -e 's/, /,/g' -e 's/.$//'  )
else
	CLIENTSM=""
fi

if [ $qcnt -gt 0 ] && [ $mcnt -eq 0 ]; 
then
	CLIENTLIST="client.list="$CLIENTSQ
else
	if [ $qcnt -eq 0 ] && [ $mcnt -gt 0 ]; 
	then
		CLIENTLIST="client.list="$CLIENTSM
	else
		if [ "$CLIENTSQ" == "$CLIENTSM" ]; 
		then
			CLIENTLIST="client.list="$CLIENTSQ
		else
			CLIENTSQH=$(echo $CLIENTSQ | sed -e 's/'"$CLIENTSM"'//' -e 's/^,//' -e 's/,$//' )
			COMBINE=$(echo $CLIENTSM", "$CLIENTSQH | sed -e 's/KTMD Base Client//2' -e 's/, ,/,/g' -e 's/,$//' )
			CLIENTLIST="client.list="$COMBINE
		fi
	fi
fi

echo ""
echo "The following are the updates for antLocalSetting.properties."
echo $BOOTSTRAPDIR | sed  -e 's/\\//' -e 's/\\//' -e 's/\\//' -e 's/\\//' -e 's/\\//' -e 's/\\//'
echo $LIBDIR | sed  -e 's/\\//' -e 's/\\//' -e 's/\\//' -e 's/\\//' -e 's/\\//' -e 's/\\//'
echo $CLIENTDIR | sed  -e 's/\\//' -e 's/\\//' -e 's/\\//' -e 's/\\//' -e 's/\\//' -e 's/\\//'
echo $DTE' 00:01' 
echo $LIBLIST
echo $CLIENTLIST
echo ""
echo -n "If everything is OK, type yes.  If not, type no."
read answer

case $answer in
	yes)
	sed -e 's/^modifiedSince.*/'"$DTE"' 00:01/' -e 's/^export.db.bootstrap.dir.*/'"$BOOTSTRAPDIR"'/' -e 's/^export.db.library.dir.*/'"$LIBDIR"'/' -e 's/^export.db.client.dir.*/'"$CLIENTDIR"'/' -e 's/^library.list=.*/'"$LIBLIST"'/' -e 's/^client.list=.*/'"$CLIENTLIST"'/' antLocalSettings.properties > als.properties
	cp als.properties antLocalSettings.properties
	echo "antLocalSettings.properties has been updated.";;
	no)
	echo -e "No Changes have been made.";;
esac	
