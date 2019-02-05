

export STARTUPLOGFILE="/var/log/startupenv.log"
echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): startup.sh script - runs once on instance startup" | sudo tee -a "$STARTUPLOGFILE"

# Export variable enscapsulated with commands and variables ...
export MYNAME=$(aws ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCEID" "Name=key,Values=Name" --region $REGION --output=text | cut -f5); echo "$MYNAME"
if [[ $MYNAME ]]; then echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): MYNAME: $MYNAME" | sudo tee -a "$STARTUPLOGFILE"; else echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): ERROR: Failed to retrieve MYNAME" | sudo tee -a "$STARTUPLOGFILE"; exit 1; fi


echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): parse dbcreds into vars." | sudo tee -a "$STARTUPLOGFILE"
for i in "${AIWEBSEC[@]}"
do
    [[ ${i} =~ "username" ]] && export IWEBUN=(${i//?username?:/}) && IWEBUN=(${IWEBUN//\"/})
    [[ ${i} =~ "password" ]] && export IWEBPW=(${i//?password?:/}) && IWEBPW=(${IWEBPW//\"/})
    [[ ${i} =~ "sid" ]] && export IWEBSID=(${i//?sid?:/}) && IWEBSID=(${IWEBSID//\"/})
done

# Test SQL DB Connection ...
echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): test db connection with sqlplus." | sudo tee -a "$STARTUPLOGFILE"
ORASTATUS=1
COUNT=0
ORAOUT=""
while [[ "${ORASTATUS}" -ne 0 ]] ; do
    echo "test for Oracle connectivity to IWEBDB"
    ORAOUT=$(echo "quit" | /usr/lib/oracle/12.2/client64/bin/sqlplus -L -S "${IWEBUN}/${IWEBPW}@${IWEBDBDNS}:1521/${IWEBSID}" )
    ORASTATUS=$(echo $? )
    COUNT=$(expr $COUNT + 1)
    TSTAMP=$(date)
    echo "Oracle Tries: ${COUNT}, at ${TSTAMP}  with status: ${ORASTATUS} and output ${ORAOUT}" | sudo tee -a "$STARTUPLOGFILE"
    sleep 1
done


# Declaring config files ...
declare -a configfiles=(/etc/yum.repos.d/adiscon-nexus.repo /etc/yum.repos.d/epel-nexus.repo /etc/yum.repos.d/nexus.repo /etc/pip.conf)
for f in "${configfiles[@]}"
do 
    sudo sed -i -e "s/unplaceholder/${UN}/g" $f
    sudo sed -i -e "s/pwplaceholder/${PW}/g" $f
done 

### EOF ###
cat << EOF > "/usr/share/tomcat/conf/Catalina/localhost/${CONTEXTPATH}.xml"
<Context
    path="${URLPATH}"
    reloadable="true"
/>
EOF


#### IFS (Internal Field Separator)
----------------------------------------------------------------------------------
Inside "domains.txt"
cyberciti.biz|202.54.1.1|/home/httpd|ftpcbzuser
nixcraft.com|202.54.1.2|/home/httpd|ftpnixuser

#!/bin/bash
# setupapachevhost.sh - Apache webhosting automation demo script
file=/tmp/domains.txt

# set the Internal Field Separator to |
IFS='|'
while read -r domain ip webroot ftpusername
do
        printf "*** Adding %s to httpd.conf...\n" $domain
        printf "Setting virtual host using %s ip...\n" $ip
        printf "DocumentRoot is set to %s\n" $webroot
        printf "Adding ftp access for %s using %s ftp account...\n\n" $domain $ftpusername


done < "$file"


$ cat $file
-- Results:

	*** Adding cyberciti.biz to httpd.conf...
Setting virtual host using 202.54.1.1 ip...
DocumentRoot is set to /home/httpd
Adding ftp access for cyberciti.biz using ftpcbzuser ftp account...

*** Adding nixcraft.com to httpd.conf...
Setting virtual host using 202.54.1.2 ip...
DocumentRoot is set to /home/httpd
Adding ftp access for nixcraft.com using ftpnixuser ftp account...
--------------------------------------------------------------------------------------------



