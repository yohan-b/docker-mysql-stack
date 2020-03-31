#!/bin/bash
#Absolute path to this script
SCRIPT=$(readlink -f $0)
#Absolute path this script is in
SCRIPTPATH=$(dirname $SCRIPT)

cd $SCRIPTPATH

test -z $1 || HOST="_$1"
test -z $2 || INSTANCE="_$2"
test -f ~/secrets.tar.gz.enc || { echo "ERROR: ~/secrets.tar.gz.enc not found, exiting."; exit 1; }
openssl enc -aes-256-cbc -d -in ~/secrets.tar.gz.enc \
| sudo tar -zxv --strip 2 secrets/docker-mysql-stack${HOST}${INSTANCE}/debian.cnf \
|| { echo "Could not extract from secrets archive, exiting."; rm -f ~/secrets.tar.gz.enc; exit 1; }
sudo chown root. debian.cnf

test -f ~/openrc.sh || { echo "ERROR: ~/openrc.sh not found, exiting."; exit 1; }
source ~/openrc.sh
export OS_REGION_NAME=GRA
test -f ~/duplicity_password.sh || { echo "ERROR: ~/duplicity_password.sh not found, exiting."; exit 1; }
source ~/duplicity_password.sh

sudo docker image inspect duplicity:latest &> /dev/null ||{ echo "ERROR: duplicity:latest image not found, exiting."; exit 1; }

rm -rf ~/build
mkdir -p ~/build
for name in docker-mysql
do  
    sudo -E docker run --rm -e SWIFT_USERNAME=$OS_USERNAME \
                            -e SWIFT_PASSWORD=$OS_PASSWORD \
                            -e SWIFT_AUTHURL=$OS_AUTH_URL \
                            -e SWIFT_AUTHVERSION=$OS_IDENTITY_API_VERSION \
                            -e SWIFT_TENANTNAME=$OS_TENANT_NAME \
                            -e SWIFT_REGIONNAME=$OS_REGION_NAME \
                            -e PASSPHRASE=$PASSPHRASE \
      --name backup-restore -v ~/build:/mnt/build --entrypoint /bin/bash duplicity:latest \
      -c "duplicity restore --name bootstrap --file-to-restore ${name}.tar.gz swift://bootstrap /mnt/build/${name}.tar.gz"
    tar -xzf ~/build/${name}.tar.gz -C ~/build/
done

unset VERSION_MYSQL
DIRECTORY=$(pwd)
cd ~/build/docker-mysql; export VERSION_MYSQL=$(git show-ref --head| head -1 | cut -f 1|cut -c -10); cd $DIRECTORY

sudo docker build -t mysql-server:$VERSION_MYSQL ~/build/docker-mysql

sudo -E bash -c 'docker-compose up --no-start --force-recreate'
# --force-recreate is used to recreate container when a file has changed
# We cannot remove the secrets files or restarting the container would become impossible
# rm -f debian.cnf
rm -rf ~/build
