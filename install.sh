#!/bin/bash


# /********************************************************/
#  Ankita N Manjrekar
#  
# /********************************************************/


USER=pi
TARGET_DIR=/usr/local/
INPUT=cluster_input.txt

# /********************************************************/
function input_node_type()
{
  echo "Enter Node Type (datanode/namenode):"
  read TYPE
}

function input_number_datanodes()
{
  echo "Enter Number of datanodes:"
  read NUM_DATANODES
}
while true; do

  input_node_type

  if [[ $TYPE == "namenode" ]] || [[ $TYPE == "datanode" ]]
  then
    echo "Installing Hadoop Environment for $TYPE"
    break
  fi
done

while true; do

  input_number_datanodes

  if [ $NUM_DATANODES -ge 1 ]
  then
     echo "Datanodes in cluster are $NUM_DATANODES"
     break
  fi
done

count=$[$NUM_DATANODES+1]

# /********************************************************/
IFS=" "
for ((i=0;;i++))
do
   read ip[$i] name[$i] || break
   done <"$INPUT"

# /********************************************************/
#  Updating hosts file
#
# /********************************************************/
HOSTS_PATH=/etc/hosts

if grep -q "127.0.1.1" "$HOSTS_PATH"; then
     sed -i '/127.0.1.1/d' $HOSTS_PATH
fi

if grep -q "${name[0]}" "$HOSTS_PATH";then
   echo "Hosts already exist"
else
   cat $INPUT >> $HOSTS_PATH
fi

# /********************************************************/
#  SSH Connection configuration
#
# /********************************************************/

function remove_existing_keys
{
for((i=0;i<=$NUM_DATANODES;i++))
do
      ssh-keygen -f "/home/pi/.ssh/known_hosts" -R "${name[$i]}"
      ssh-keygen -f "/home/pi/.ssh/known_hosts" -R "${ip[$i]}"
      done

}

function copy_ssh_key
{
   i=0
for((i=0;i<=$NUM_DATANODES;i++))
do
      echo ${name[$i]}
      sudo -u pi ssh-copy-id pi@${name[$i]}
      done

}

remove_existing_keys
sudo -u pi ssh-keygen -t rsa -N ""
chown pi /home/pi/.ssh/known_hosts*
copy_ssh_key

# /********************************************************/
#  Hadoop version 2.6.4
#
# /********************************************************/

wget=/usr/bin/wget
tar=/bin/tar

URL_BASE="http://mirror.jax.hugeserver.com/apache/hadoop/common/hadoop-2.6.4/hadoop-2.6.4.tar.gz"

if [ ! -d "$TARGET_DIR" ]; then

   echo "Change target directory"
   exit 1
fi

rm -rf $TARGET_DIR/hadoop-2.6.4.tar.gz*

if ! $wget -P "$TARGET_DIR" $URL_BASE; then
    echo "Enter valid URL"
    exit 1
fi

tar zxvf "$TARGET_DIR/hadoop-2.6.4.tar.gz" -C "$TARGET_DIR"

rm -rf "$TARGET_DIR/hadoop"

mv "$TARGET_DIR/hadoop-2.6.4" "$TARGET_DIR/hadoop"

# /********************************************************/

HADOOP_SETUP_DIR="$TARGET_DIR/hadoop/etc/hadoop"

rm -rf "$HADOOP_SETUP_DIR/mapred-site.xml.template"
rm -rf "$HADOOP_SETUP_DIR/core-site.xml"
rm -rf "$HADOOP_SETUP_DIR/yarn-site.xml"
rm -rf "$HADOOP_SETUP_DIR/hdfs-site.xml"
rm -rf "$HADOOP_SETUP_DIR/slaves"

touch "$HADOOP_SETUP_DIR/mapred-site.xml.template"
touch "$HADOOP_SETUP_DIR/core-site.xml"
touch "$HADOOP_SETUP_DIR/yarn-site.xml"
touch "$HADOOP_SETUP_DIR/hdfs-site.xml"
touch "$HADOOP_SETUP_DIR/slaves"

# /********************************************************/
#  Hadoop map-reduce environment configuration
#
# /********************************************************/

echo "<configuration>
    <property>
        <name>mapreduce.job.tracker</name>
        <value>${name[0]}:5431</value>
    </property>
    <property>
        <name>mapred.framework.name</name>
        <value>yarn</value>
    </property>
</configuration>" > "$HADOOP_SETUP_DIR/mapred-site.xml"

# /********************************************************/
#  Hadoop yarn environment configuration
#
# /********************************************************/

echo "<configuration>
<!-- Site specific YARN configuration properties -->
    <property>
        <name>yarn.resourcemanager.resource-tracker.address</name>
        <value>${name[0]}:8025</value>
    </property>
    <property>
        <name>yarn.resourcemanager.scheduler.address</name>
        <value>${name[0]}:8035</value>
    </property>
    <property>
        <name>yarn.resourcemanager.address</name>
        <value>${name[0]}:8050</value>
    </property>
</configuration>" > "$HADOOP_SETUP_DIR/yarn-site.xml"

# /********************************************************/
#  Hadoop core environment configuration
#
# /********************************************************/

echo "<configuration>
    <property>
        <name>fs.default.name</name>
        <value>hdfs://${name[0]}:9000/</value>
    </property>
    <property>
        <name>fs.default.FS</name>
        <value>hdfs://${name[0]}:9000/</value>
    </property>

</configuration>" > "$HADOOP_SETUP_DIR/core-site.xml"
# /********************************************************/
#  Hadoop slaves configuration
#
# /********************************************************/

for((i=1;i<=$NUM_DATANODES;i++))
do
      echo "${name[$i]}" >> "$HADOOP_SETUP_DIR/slaves"
      done


# /********************************************************/
#  Hadoop dfs environment configuration
#
# /********************************************************/

if [ "$TYPE" == "datanode" ];then

echo "<configuration>
    <property>
        <name>dfs.datanode.data.dir</name>
        <value>/usr/local/hadoop_tmp/hdfs/datanode</value>
        <final>true</final>
    </property>
    <property>
        <name>dfs.permissions.enabled</name>
        <value>false</value>
    </property>
     <property>
        <name>dfs.namenode.http-address</name>
        <value>${name[0]}:50070</value>
    </property>
    <property>
        <name>dfs.replication</name>
        <value>$NUM_DATANODES</value>
    </property>
</configuration>" > "$HADOOP_SETUP_DIR/hdfs-site.xml"

elif [ "$TYPE" == "namenode" ];then

echo "<configuration>
    <property>
        <name>dfs.namenode.name.dir</name>
        <value>/usr/local/hadoop_tmp/hdfs/namenode</value>
        <final>true</final>
    </property>
    <property>
         <name>dfs.permissions.enabled</name>
         <value>true</value>
    </property>
    <property>
      <name>dfs.namenode.datanode.registration.ip-hostname-check</name>
      <value>false</value>
    </property>
    <property>
        <name>dfs.namenode.http-address</name>
        <value>${name[0]}:50070</value>
    </property>
    <property>
        <name>dfs.replication</name>
        <value>$NUM_DATANODES</value>
    </property>
</configuration>" > "$HADOOP_SETUP_DIR/hdfs-site.xml"

fi

# /********************************************************/
HADOOP_ENV_PATH=/usr/local/hadoop/etc/hadoop/hadoop-env.sh

N=$(grep -n "export JAVA_HOME=" "$HADOOP_ENV_PATH" | cut -d : -f 1)

expression2="export JAVA_HOME=\/usr\/lib\/jvm\/jdk-8-oracle-arm32-vfp-hflt\/jre"
lineNo=$N
sed -i "${lineNo}s/.*/$expression2/" $HADOOP_ENV_PATH

# /********************************************************/
function create_hdfs_datanode
{

     if [ -d "$TARGET_DIR/hadoop_tmp" ]; then
          rm -r "$TARGET_DIR/hadoop_tmp"
     fi

     mkdir "$TARGET_DIR/hadoop_tmp"
     mkdir "$TARGET_DIR/hadoop_tmp/hdfs"
     mkdir "$TARGET_DIR/hadoop_tmp/hdfs/datanode"
}

function create_hdfs_namenode
{
     if [ -d "$TARGET_DIR/hadoop_tmp" ]; then
          rm -r "$TARGET_DIR/hadoop_tmp"
     fi

     mkdir "$TARGET_DIR/hadoop_tmp"
     mkdir "$TARGET_DIR/hadoop_tmp/hdfs"
     mkdir "$TARGET_DIR/hadoop_tmp/hdfs/namenode"
}

if [ "$TYPE" == "datanode" ];then
  create_hdfs_datanode
  elif [ "$TYPE" == "namenode" ];then
  create_hdfs_namenode
fi


chown -R $USER "$TARGET_DIR/hadoop"
chown -R $USER "$TARGET_DIR/hadoop_tmp"
# /********************************************************/


BASHRC_PATH=/home/pi/.bashrc

if grep -q "export HADOOP_HOME=/usr/local/hadoop" "$BASHRC_PATH"; then
   echo "Environment variables already present"
else
	echo "export HADOOP_HOME=/usr/local/hadoop" >> "$BASHRC_PATH"
	echo "export PATH=\$PATH:\$HADOOP_HOME/bin" >> "$BASHRC_PATH"
	echo "export PATH=\$PATH:\$HADOOP_HOME/sbin" >> "$BASHRC_PATH"
	echo "export HADOOP_MAPRED_HOME=\$HADOOP_HOME" >> "$BASHRC_PATH"
	echo "export HADOOP_COMMON_HOME=\$HADOOP_HOME" >> "$BASHRC_PATH"
	echo "export HADOOP_HDFS_HOME=\$HADOOP_HOME" >> "$BASHRC_PATH"
	echo "export YARN_HOME=\$HADOOP_HOME" >> "$BASHRC_PATH"
	echo "export HADOOP_COMMON_LIB_NATIVE_DIR=\$HADOOP_HOME/lib/native" >> "$BASHRC_PATH"
	echo "export HADOOP_OPTS="-Djava.library.path=\$HADOOP_HOME/lib"" >> "$BASHRC_PATH"
# -- HADOOP ENVIRONMENT VARIABLES END -- #
	echo "export JAVA_HOME=/usr/lib/jvm/jdk-8-oracle-arm32-vfp-hflt/jre" >> "$BASHRC_PATH"

source /home/pi/.bashrc
fi

