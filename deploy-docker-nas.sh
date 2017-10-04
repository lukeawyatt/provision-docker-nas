#!/bin/bash
###########################################
## UBUNTU-NAS-DOCKER PROVISIONING SCRIPT ##
## ******** RUN AS A SUPERUSER ********* ##
##                                       ##
## Author:                   Luke Wyatt  ##
## Contact:            <luke@meat.space> ##
## Create Date:               2017.10.02 ##
## Last Modified Date:        2017.10.04 ##
###########################################

# REQUIREMENTS:
# ****************
# Ubuntu 16.04 LTS
# Docker >= 17.09
# Mounted Backup Hard Drive (Optional)

# PRELIMINARY CONFIGURATION
# *************************
#
# This is the name of the host, local to this configuration only.
# Use only ALPHA-NUMERIC characters with no spaces. The script will 
# automatically append '.local' to your entered value.
HOST=GIBSON
#
# This is the system user used to assign permissions to the share directories.
USR=lwyatt
#
# This is the mount path of the physical hard drive or parent share directory.
# Note, a "share" directory will be created with the supplied heirarchy.
# LEAVE OFF TRAILING FORWARD SLASH
IHDD1="/GIBSON/physical/IHDD1"
#
# This is the mount path of the backup hard drive or backup parent share 
# directory. Note, a "share" directory will be created with the supplied 
# heirarchy. Comment this out if you do not want backups to be set.
# LEAVE OFF TRAILING FORWARD SLASH
IHDD2="/GIBSON/physical/IHDD2"
#
# This is the user array. Each key of this associative array represents a
# share by name. The semicolon delimited (;) value represents the below:
# Place: 1 - Username
# Place: 2 - Password
declare -A USERS=(
	["readuser"]="read"
	["writeuser"]="write"
)
#
# This is the share array. Each key of this associative array represents a
# share by name. The semicolon delimited (;) value represents the below:
# Place: 1 - Browsable (yes or no)
# Place: 2 - Readonly (yes or no)
# Place: 3 - Guest (yes or no)
# Place: 4 - Users (Comma Delimited), Or 'all'
# Place: 5 - Admins (Comma Delimited), Or 'none'
# Place: 6 - Users with Write Permission Whitelist (On RO) (Comma Delimited)
declare -A SHARES=(
	["Archives"]="yes;no;no;all;writeuser;writeuser"
	["BroadcastSeries"]="yes;yes;yes;all;writeuser;writeuser"
	["Cinema"]="yes;yes;yes;all;writeuser;writeuser"
	["FamilyImages"]="yes;no;no;all;writeuser;writeuser"
	["FamilyVideo"]="yes;no;no;all;writeuser;writeuser"
	["Literature"]="yes;yes;yes;all;writeuser;writeuser"
	["Music"]="yes;yes;yes;all;writeuser;writeuser"
	["Software"]="yes;yes;yes;all;writeuser;writeuser"
	["Staging"]="yes;yes;yes;all;writeuser;writeuser"
	["WorkspaceAudio"]="yes;no;no;all;writeuser;writeuser"
	["WorkspaceDevelopment"]="yes;no;no;all;writeuser;writeuser"
	["WorkspaceGaming"]="yes;no;no;all;writeuser;writeuser"
	["WorkspaceGraphics"]="yes;no;no;all;writeuser;writeuser"
	["WorkspaceVideo"]="yes;no;no;all;writeuser;writeuser"
)



# LEAVE EVERYTHING ALONE BELOW THIS LINE
# **************************************
# SYSTEM SETUP
echo "1) SYSTEM SETUP"
systemctl enable docker
echo;echo;


# PULL NAS DOCKER IMAGES
echo "2.A) PULLING PORTAINER IMAGES"
docker pull portainer/portainer:latest
echo;

echo "2.B) PULLING SAMBA IMAGES"
docker pull dperson/samba:latest
echo;echo;



# STAGE ENVIRONMENT
echo "3.A) STAGING NAS CONTAINERS"
echo;

echo "Initializing system vars..."
UID=$(id -u $USR)
GID=$(id -g $USR)

echo "Stopping existing Portainer container if exists..."
docker stop Portainer
echo "Removing existing Portainer container if exists..."
docker rm Portainer
echo;

echo "Stopping existing Samba container if exists..."
docker stop Samba
echo "Removing existing Samba container if exists..."
docker rm Samba
echo;

echo "3.B) STAGING ENVIRONMENT"
echo "Creating folder structure..."

echo "/$HOST/volumes"
mkdir -p "/$HOST/volumes"

echo "$IHDD1/shares"
mkdir -p "$IHDD1/shares"

for i in "${!SHARES[@]}"
do
	echo "$IHDD1/shares/$i"
	mkdir -p "$IHDD1/shares/$i"
done
chown $USR:$USR "$IHDD1/shares" -R

echo "$IHDD2/shares"
mkdir -p "$IHDD2/shares"
chown $USR:$USR "$IHDD2/shares" -R
echo;echo;



# RUN NAS CONTAINERS
echo "4.A) LAUNCH PORTAINER CONTAINER"
docker run \
	--volume /var/run/docker.sock:/var/run/docker.sock \
	--volume "/$HOST/volumes/portainer:/data" \
	--restart=unless-stopped \
	--publish=80:9000 \
	--detach=true \
	--name=Portainer \
	portainer/portainer:latest
echo;echo;

echo "4.B) LAUNCH SAMBA CONTAINER"
docker run \
	--volume "$IHDD1/shares:/mount" \
	--env USERID=$UID \
	--env GROUPID=$GID \
	--network="host" \
	--publish=137:137/udp \
	--publish=138:138/udp \
	--publish=139:139 \
	--publish=445:445 \
	--detach=true \
	--name=Samba \
	dperson/samba:latest \
	-n -p -S -w "$HOST.local"

echo "Creating users..."
for i in "${!USERS[@]}"
do
	echo "User: $i"
	docker exec -d Samba samba.sh -u "$i;${USERS[$i]}"
done

echo "Creating shares..."
for i in "${!SHARES[@]}"
do
	echo "Share: $i"
	docker exec -d Samba samba.sh -s "$i;/mount/$i;${SHARES[$i]}"
done

docker restart Samba
echo;echo;



# CLEANUP
echo "5) DOCKER CLEANUP TIME"
echo "Removing empty containers..."
docker system prune -a -f
# FOR USE WITH DOCKER ENGINE <= 1.13
# echo "NOTE THIS WILL ERROR WHEN NOTHING NEEDS TO BE CLEANED UP"
# docker rm -v $(docker ps -a -q -f status=exited)
# echo "Removing unused images..."
# echo "NOTE THIS WILL ERROR WHEN NOTHING NEEDS TO BE CLEANED UP"
# docker rmi $(docker images -f "dangling=true" -q)
echo;echo;



# SETUP SYNC JOB
if [ -z ${IHDD2+x} ]; then 
	echo "6) NO BACKUP PATH SPECIFIED, REMOVING SYNC AGENT JOB IF FOUND"
	rm -f "/etc/cron.daily/${HOST,,}"
else 
	echo "6) CREATING/UPDATING SYNC JOB"
	echo "File list will output below"
	HDR='#!/bin/bash'
	bash -c "printf '$HDR\n' > /etc/cron.daily/${HOST,,}"
	bash -c "printf 'rsync -av --delete $IHDD1/shares $IHDD2' >> /etc/cron.daily/${HOST,,}"
	chmod ug+x "/etc/cron.daily/${HOST,,}"
	ls "/etc/cron.daily/${HOST,,}"
	echo;echo;
fi



# PROVISIONED OUTPUT
echo "YOUR PROVISIONED PATHS - COPY FOR YOUR RECORDS:"
echo "Volume Root: /$HOST/volumes/"
echo "Portainer Volume: /$HOST/volumes/portainer"
echo "Portainer Address: http://$HOST"
echo "Portainer Address (Local IP): http://127.0.0.1"
echo "Root Share Directory: $IHDD1/shares"

if [ -z ${IHDD2+x} ]; then 
	echo "Backup Share Directory: NONE"
	echo "Backup Job: NONE"
else
	echo "Backup Share Directory: $IHDD2/shares"
	echo "Backup Job: /etc/cron.daily/${HOST,,}"
fi

for i in "${!SHARES[@]}"
do
	echo "$IHDD1/shares/$i"
done
