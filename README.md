# Docker NAS Provisioning Script

This script is intended to provision a NAS solution based on container technology.  With a lack of available options for home use, I decided to create a simple one that meets my direct needs.  This script offers a quick solution to provision the following:

* A Samba container with NetBIOS agent to advertise shares - [Samba for Docker](https://github.com/dperson/samba)
* A nightly backup job that syncs your fileshare to another source
* Portainer managment UI for your local docker environment - [Portainer](https://github.com/portainer/portainer)


#### Requirements

* Ubuntu Server 16.04 LTS
* Docker >= 17.09
* Mounted Storage and Backup Hard Drives (Optional)


## Usage

Pull down the script 

```shell
wget https://raw.githubusercontent.com/lukeawyatt/provision-docker-nas/master/deploy-docker-nas.sh -O deploy-docker-nas.sh
```

Modify the permissions to allow execution

```shell
chmod u+x deploy-docker-nas.sh
```

Edit the script to change our configuration

```shell
vim deploy-docker-nas.sh
```

Execute the script with superuser privileges to provision the NAS.  Clip the output for your records.  This script can be re-ran since it'll break down the existing containers first.  If your paths change, re-running the script will leave the residual files as they exist.  This script can also be re-ran as is to upgrade the base docker images.
```shell
sudo ./deploy-docker-nas.sh
```


## Configuration

Edit the PRELIMINARY CONFIGURATION section of the script to your desired setting.  

#### HOST
This is the name of the host, local to this configuration only. Use only ALPHA-NUMERIC characters with no spaces. The script will automatically append '.local' to your entered value.

```shell
HOST=GIBSON
```

#### USR
This is the system user used to assign permissions to the share directories.

```shell
USR=lwyatt
```

#### IHDD1
This is the mount path of the physical hard drive or parent share directory.
Note, a "share" directory will be created with the supplied heirarchy.
LEAVE OFF TRAILING FORWARD SLASH

```shell
IHDD1="/GIBSON/physical/IHDD1"
```

#### IHDD2
This is the mount path of the backup hard drive or backup parent share 
directory. Note, a "share" directory will be created with the supplied 
heirarchy. Comment this out if you do not want backups to be set.
LEAVE OFF TRAILING FORWARD SLASH

```shell
IHDD2="/GIBSON/physical/IHDD2"
```

#### USERS
This is the user array. Each key of this associative array represents a
share by name. The semicolon delimited (;) value represents the below:

* Place: 1 - Username
* Place: 2 - Password


```shell
declare -A USERS=(
	["readuser"]="read"
	["writeuser"]="write"
)
```

#### SHARES
This is the share array. Each key of this associative array represents a
share by name. The semicolon delimited (;) value represents the below:

* Place: 1 - Browsable (yes or no)
* Place: 2 - Readonly (yes or no)
* Place: 3 - Guest (yes or no)
* Place: 4 - Users (Comma Delimited), Or 'all'
* Place: 5 - Admins (Comma Delimited), Or 'none'
* Place: 6 - Users with Write Permission Whitelist (On RO) (Comma Delimited)


```shell
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
```


## Upgrading

When new versions of the packaged Dockerhub images are released, simply re-run this script to upgrade.  The new image will be downloaded and utilized during re-build.


## Tested Versions

My test environment is as follows.  If you have tested in another environment/version set, please add to this list.

* Ubuntu 20.04 LTS
* GNU Bash
* Docker CE 17.09.0
* Samba 4.5.8 (Docker)
* Portainer 1.14.3
* rsync 3.1.1 pv 31


## ToDo

* Configuration Validation
* Create and attach volumes separately to prevent strays at re-provision
* Add a Docker health check
* Create a basic Samba management webapp, since this will complete the technical definition of a NAS
* Optional recycle bin
* Optional docker cleanup process


## Feedback

If you have any problems with or questions about this script, please contact me using a [GitHub Issue](https://github.com/lukeawyatt/provision-docker-nas/issues)
