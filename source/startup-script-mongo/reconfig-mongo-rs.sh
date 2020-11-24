#!/bin/bash

retryCount=0

echo "Checking MongoDB status:"

while [[ $(mongo --quiet --eval "rs.conf()._id") != rs0 ]]
do
    if [ $retryCount -gt 300 ]
    then
        echo "Retry count > 300, breaking out of while loop now..."
        break
    fi
    echo "MongoDB not ready for Replica Set configuration, retrying in 10 seconds..."
    sleep 10
    retryCount=$((retryCount+1))
done

echo "Sending in Replica Set configuration..."
echo "mongodb = ['$MONGODB_0_SERVICE_SERVICE_HOST:$MONGODB_0_SERVICE_SERVICE_PORT', '$MONGODB_1_SERVICE_SERVICE_HOST:$MONGODB_1_SERVICE_SERVICE_PORT', '$MONGODB_2_SERVICE_SERVICE_HOST:$MONGODB_2_SERVICE_SERVICE_PORT']"

mongo --eval "mongodb = ['$MONGODB_0_SERVICE_SERVICE_HOST:$MONGODB_0_SERVICE_SERVICE_PORT', '$MONGODB_1_SERVICE_SERVICE_HOST:$MONGODB_1_SERVICE_SERVICE_PORT', '$MONGODB_2_SERVICE_SERVICE_HOST:$MONGODB_2_SERVICE_SERVICE_PORT']" --shell << EOL
cfg = rs.conf()
cfg.members[0].host = mongodb[0]
cfg.members[1].host = mongodb[1]
cfg.members[2].host = mongodb[2]
rs.reconfig(cfg, {force: true})
EOL

sleep 5

if [[ $(mongo --quiet --eval "db.isMaster().setName") != rs0 ]]
then
    echo "Replica Set reconfiguratoin failed..."
    echo "Reinitializing Replica Set..."
    /root/initialize-mongo-rs.sh &
else
    echo "Replica Set reconfiguratoin successful..."
fi