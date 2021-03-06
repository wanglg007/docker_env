#!/usr/bin/env bash

set -x

PREFIX="-------- "
echo $PREFIX"Bootstraping hadoop..."

SSH_NEW_PORT=12022

if [ "$SSH_PORT" !=  "" ]; then
  SSH_NEW_PORT=$SSH_PORT
fi

echo $PREFIX"Updating ssh port to "$SSH_NEW_PORT
sed -i "s|Port 22|Port $SSH_NEW_PORT|g" /etc/ssh/sshd_config

#cat /etc/ssh/sshd_config
CONFIG_DIR=/etc/hadoop/conf
CONFIG_HIVE_DIR=/etc/hive/conf
export HADOOP_SSH_OPTS="-p $SSH_NEW_PORT"

echo $PREFIX"Starting ssh..."
service ssh start;

# DEFAULTS
RESOURCEMANAGER_ADDRESS=0.0.0.0
RESOURCEMANAGER_WEBPORT=8088
RESOURCEMANAGER_SCHEDULERPORT=8030
RESOURCEMANAGER_TRACKERPORT=8031
RESOURCEMANAGER_PORT=8032
RESOURCEMANAGER_ADMINPORT=8033

NAMENODE_ADDRESS=0.0.0.0
NAMENODE_PORT=9000
NAMENODE_WEBPORT=50070
SECOND_NAMENODE_WEBPORT=50090

# ALB_ADDR=0.0.0.0

YARN_MIN_MB=128
YARN_MAX_MB=2048
YARN_MIN_VCORE=1
YARN_MAX_VCORE=2
YARN_MEMORY=4096
YARN_VCORES=4

DEFAULT_DATA_DIR=/data/hdfs/
chown -R hdfs:hdfs $DEFAULT_DATA_DIR

mkdir -p /data/flume
chown -R flume:flume /data/flume

# data dir should be "/data/hdfs,/data1/hdfs,/data2/hdfs" and so on.

#

if [ "$YARN_MIN_ALLOC" != "" ]; then
  YARN_MIN_MB = $YARN_MIN_ALLOC
fi

if [ "$YARN_MAX_ALLOC" != "" ]; then
  YARN_MAX_MB = $YARN_MAX_ALLOC
fi

if [ "$YARN_MIN_VCORES_NUM" != "" ]; then
  YARN_MIN_VCORE = $YARN_MIN_VCORES_NUM
fi

if [ "$YARN_MAX_VCORES_NUM" != "" ]; then
  YARN_MAX_VCORE = $YARN_MAX_VCORES_NUM
fi

if [ "$YARN_RESOURCE_MEM" != "" ]; then
  YARN_MEMORY = $YARN_RESOURCE_MEM
fi

if [ "$YARN_CORES" != "" ]; then
  YARN_VCORES = $YARN_CORES
fi

if [ "$DATA_DIR" != "" ]; then
  DEFAULT_DATA_DIR=$DATA_DIR
fi

echo $PREFIX"prepare dir"
# mkdir -p $DEFAULT_DATA_DIR
mkdir -p /data/tmp

# Setup ssh for slaves
if [ "$DEFAULT_DATA_DIR" != "" ]; then
  echo $PREFIX"Got data dir as "$DEFAULT_DATA_DIR

  data_dir=""
  if echo $DEFAULT_DATA_DIR | grep -q ","
  then
    #Multiple nodes
    data_dir=$(echo $DEFAULT_DATA_DIR | tr "," "\n")
  else
    #Single node
    data_dir=$DEFAULT_DATA_DIR
  fi

  for dir in $data_dir
  do
    mkdir -p $dir
    chown -R hdfs:hdfs $dir
  done
fi

mkdir -p $NAME_DIR
chown -R hdfs:hdfs $NAME_DIR

mkdir -p $DATA_DIR
chown -R hdfs:hdfs $DATA_DIR

mkdir -p $TMP_DIR
chown -R hdfs:hdfs $TMP_DIR

yarn_dir=""
if echo $YARN_DIR | grep -q ","
then
  yarn_dir=$(echo $YARN_DIR | tr "," "\n")
else
  yarn_dir=$YARN_DIR
fi

for dir in $yarn_dir
do
  mkdir -p $dir/{local,logs}
  chown -R yarn:yarn $dir
done


echo $PREFIX"Namenode configuration"


if [ "$NAME_NODE_ADDR" != "" ]; then
  RESOURCEMANAGER_ADDRESS=$NAME_NODE_ADDR
  NAMENODE_ADDRESS=$NAME_NODE_ADDR
fi

if [ "$NAME_NODE_PORT" != "" ]; then
  NAMENODE_PORT=$NAME_NODE_PORT
fi

echo $PREFIX"Setting up hadoop configuration..."
sed -i "s|{{resourcemanager.address}}|$RESOURCEMANAGER_ADDRESS|g" $CONFIG_DIR/yarn-site.xml
sed -i "s|{{resourcemanager.webport}}|$RESOURCEMANAGER_WEBPORT|g" $CONFIG_DIR/yarn-site.xml
sed -i "s|{{resourcemanager.schedulerport}}|$RESOURCEMANAGER_SCHEDULERPORT|g" $CONFIG_DIR/yarn-site.xml
sed -i "s|{{resourcemanager.trackerport}}|$RESOURCEMANAGER_TRACKERPORT|g" $CONFIG_DIR/yarn-site.xml
sed -i "s|{{resourcemanager.port}}|$RESOURCEMANAGER_PORT|g" $CONFIG_DIR/yarn-site.xml
sed -i "s|{{resourcemanager.adminport}}|$RESOURCEMANAGER_ADMINPORT|g" $CONFIG_DIR/yarn-site.xml

sed -i "s|{{yarn.min-mb}}|$YARN_MIN_MB|g" $CONFIG_DIR/yarn-site.xml
sed -i "s|{{yarn.max-mb}}|$YARN_MAX_MB|g" $CONFIG_DIR/yarn-site.xml
sed -i "s|{{yarn.min-vcore}}|$YARN_MIN_VCORE|g" $CONFIG_DIR/yarn-site.xml
sed -i "s|{{yarn.max-vcore}}|$YARN_MAX_VCORE|g" $CONFIG_DIR/yarn-site.xml
sed -i "s|{{yarn.memory}}|$YARN_MEMORY|g" $CONFIG_DIR/yarn-site.xml
sed -i "s|{{yarn.vcores}}|$YARN_VCORES|g" $CONFIG_DIR/yarn-site.xml

sed -i "s|{{node.name.ip}}|$NAMENODE_ADDRESS|g" $CONFIG_DIR/hdfs-site.xml
sed -i "s|{{node.name.ip}}|$NAMENODE_ADDRESS|g" $CONFIG_DIR/core-site.xml
sed -i "s|{{node.name.ip}}|$NAMENODE_ADDRESS|g" $CONFIG_DIR/mapred-site.xml
sed -i "s|{{node.name.ip}}|$NAMENODE_ADDRESS|g" $CONFIG_DIR/yarn-site.xml

sed -i "s|{{node.name.port}}|$NAMENODE_PORT|g" $CONFIG_DIR/hdfs-site.xml
sed -i "s|{{node.name.port}}|$NAMENODE_PORT|g" $CONFIG_DIR/core-site.xml

sed -i "s|{{secondary.node.name.ip}}|$SECOND_NAME_NODE_ADDR|g" $CONFIG_DIR/hdfs-site.xml
sed -i "s|{{secondary.node.name.webport}}|$SECOND_NAMENODE_WEBPORT|g" $CONFIG_DIR/hdfs-site.xml

sed -i "s|{{HADOOP_HEAPSIZE}}|$HADOOP_HEAPSIZE|g" $CONFIG_DIR/hadoop-env.sh

sed -i "s|{{node.name.webport}}|$NAMENODE_WEBPORT|g" $CONFIG_DIR/hdfs-site.xml

sed -i "s|{{hdfs.data.dir}}|$DEFAULT_DATA_DIR|g" $CONFIG_DIR/hdfs-site.xml
sed -i "s|{{hdfs.name.dir}}|$NAME_DIR|g" $CONFIG_DIR/hdfs-site.xml
sed -i "s|{{hdfs.tmp.data}}|$NAME_DIR|g" $CONFIG_DIR/core-site.xml

sed -i "s|{{HIVE_MYSQL_ADDR}}|$HIVE_MYSQL_ADDR|g" $CONFIG_HIVE_DIR/hive-site.xml
sed -i "s|{{HIVE_MYSQL_PORT}}|$HIVE_MYSQL_PORT|g" $CONFIG_HIVE_DIR/hive-site.xml
sed -i "s|{{NAME_NODE_ADDR}}|$NAMENODE_ADDRESS|g" $CONFIG_HIVE_DIR/hive-site.xml

sed -i "s|{{IMPALA_CATALOG_SERVICE_HOST}}|$IMPALA_CATALOG_SERVICE_HOST|g" /etc/default/impala
sed -i "s|{{IMPALA_STATE_STORE_HOST}}|$IMPALA_STATE_STORE_HOST|g" /etc/default/impala
sed -i "s|{{KUDU_MASTER_HOST}}|$KUDU_MASTER_HOST|g" /etc/default/impala

# debuging configuration
if [ "$DEBUG" != "" ]; then
  cat $CONFIG_DIR/yarn-site.xml
fi

echo "" > $CONFIG_DIR/slaves

if [ "$SECOND_NAME_NODE_ADDR" != "" ]; then
  # echo "" > $CONFIG_DIR/slaves
  echo $PREFIX"Got secondary name nodes address as "$SECOND_NAME_NODE_ADDR
  echo "Host "$SECOND_NAME_NODE_ADDR >> ~/.ssh/config
  echo "  StrictHostKeyChecking no" >> ~/.ssh/config
  echo "" >> ~/.ssh/config
fi

# Setup ssh for slaves
if [ "$NODE_IPS" != "" ]; then
  echo $PREFIX"Got nodes address as "$NODE_IPS

  nodes=""
  if echo $NODE_IPS | grep -q ","
  then
    #Multiple nodes
    nodes=$(echo $NODE_IPS | tr "," "\n")
  else
    #Single node
    nodes=$NODE_IPS
  fi
  # echo "" > $CONFIG_DIR/slaves
  for addr in $nodes
  do
    echo $PREFIX"Setup for node "$addr
    echo $addr >> $CONFIG_DIR/slaves
    echo "Host "$addr >> ~/.ssh/config
    echo "  StrictHostKeyChecking no" >> ~/.ssh/config
    echo "" >> ~/.ssh/config

    # echo $PREFIX"Will try to connect to node "$addr
    # ssh -v $addr $HADOOP_SSH_OPTS exit
  done
fi

if [ "$SERVER_ROLE" = "nn" ]; then
    echo $PREFIX"Will start as namenode"

    if [ "$FORMAT_NAMENODE" = "true" ]; then

        VERSION_LOCATION=$DEFAULT_DATA_DIR/current/VERSION
        echo $PREFIX" Data dir will be verified by "$VERSION_LOCATION
        if [ ! -f $VERSION_LOCATION ]; then
          echo $PREFIX"Will format namenode"
          sudo -u hdfs hadoop namenode -format -nonInteractive
        else
          echo $PREFIX"Namenode is already formatted"
        fi   
    fi

    # sleep 5
    echo $PREFIX"Will start namenode hdfs in the background"
    # for x in `ls /etc/init.d/|grep  hadoop-hdfs` ; do service $x start ; done
    service hadoop-hdfs-namenode start

    sleep 60

    if [ "$FORMAT_NAMENODE" = "true" ]; then
      echo $PREFIX"init hive"
      /usr/lib/hive/bin/schematool --dbType mysql --initSchema
    fi

    echo $PREFIX"Will start namenode yarn in the background"
    # for x in `ls /etc/init.d/|grep hadoop-yarn` ; do service $x start ; done
    service hadoop-yarn-resourcemanager start

    echo $PREFIX"Will start namenode yarn proxy in the background"
    service hadoop-yarn-proxyserver start

    echo $PREFIX"Will start namenode yarn historyserver in the background"
    /etc/init.d/hadoop-mapreduce-historyserver start


elif [ "$SERVER_ROLE" = "sn" ]; then
  echo $PREFIX"Will start as second namenode"
  sleep 10
  echo $PREFIX"Will start second namenode hdfs in the background"
  service hadoop-hdfs-secondarynamenode start

  sleep 120
  echo $PREFIX"Will start hive components"
  service hive-metastore start
  sleep 5
  service hive-server2 start

  # sleep 30
  # echo $PREFIX"Will start impala components"
  # service impala-state-store start
  # sleep 5
  # service impala-catalog start

elif [ "$SERVER_ROLE" = "flume" ]; then
  echo $PREFIX"Will start as flume"
  sleep 20
  service flume-ng-agent start

else
  echo $PREFIX"Will start as data node"

  sleep 10
  echo $PREFIX"Will start datanode hdfs in the background"
  service hadoop-hdfs-datanode start

  sleep 60
  echo $PREFIX"Will start datanode yarn in the background"
  service hadoop-yarn-nodemanager start

  # sleep 180
  # echo $PREFIX"Will start impala components"
  # service impala-server start

fi


echo $PREFIX"Tailing logs..."
mkdir -p /opt/hadoop/logs/
echo "first line" > /opt/hadoop/logs/first
tail -f /opt/hadoop/logs/* 

wait || :
