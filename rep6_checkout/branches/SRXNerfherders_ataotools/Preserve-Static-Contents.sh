 #!/bin/sh

 app_server_dir=E:/sandbox/jboss405
 script_dir=`pwd`
 # JBOSS_HOME environment variable must be set
 
if [ -n "$JBOSS_HOME" ]
then
    app_server_dir=$JBOSS_HOME
    jboss_deploy_path=$1
    ls ${app_server_dir}/server/${jboss_deploy_path}/deploy/atao.ear/atao.war/static > ${script_dir}/Static_list_current.txt 2>&1 
    ls ${app_server_dir}.old/server/${jboss_deploy_path}/deploy/atao.ear/atao.war/static > ${script_dir}/Static_list_previous.txt 2>&1
    sort ${script_dir}/Static_list_current.txt > ${script_dir}/temp.txt
    mv ${script_dir}/temp.txt ${script_dir}/Static_list_current.txt
    sort ${script_dir}/Static_list_previous.txt > ${script_dir}/temp.txt
    mv ${script_dir}/temp.txt ${script_dir}/Static_list_previous.txt
    comm -23 ${script_dir}/Static_list_previous.txt ${script_dir}/Static_list_current.txt > ${script_dir}/Static_list_unique.txt
    totallines=`cat ${script_dir}/Static_list_unique.txt | wc -l`
    i=1
    while [ $i -le $totallines ]
    do
   	static_item=`cat ${script_dir}/Static_list_unique.txt | sed 1q`
   	echo "Copying  ${static_item} from ${app_server_dir}.old...to ${app_server_dir}"
    	echo
    	cp -pr "${app_server_dir}.old/server/${jboss_deploy_path}/deploy/atao.ear/atao.war/static/${static_item}" "${app_server_dir}/server/${jboss_deploy_path}/deploy/atao.ear/atao.war/static"
    	i=`expr $i + 1`
    	cat ${script_dir}/Static_list_unique.txt | grep -v "${static_item}" > ${script_dir}/temp.txt
    	echo
    	if [ -s ${script_dir}/temp.txt ]
    	then
    	mv ${script_dir}/temp.txt ${script_dir}/Static_list_unique.txt
    	fi
    done
    exit 0
else
   echo "ERROR: variable JBOSS_HOME must be set!"
   exit 1
 fi
