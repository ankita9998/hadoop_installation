#!/bin/bash

USER=pi
TARGET_DIR=/usr/local/

# /********************************************************/
#  Hadoop version 2.6.4
#
# /********************************************************/

wget=/usr/bin/wget
tar=/bin/tar

URL_BASE="http://mirror.jax.hugeserver.com/apache/hadoop/common/hadoop-2.6.4/hadoop-2.6.4.tar.gz"

if ! cd "$TARGET_DIR"; then

   echo "Change target directory"
fi

if ! $wget $URL_BASE; then
    echo "Enter valid URL"
fi

if "$TARGET_DIR/hadoop-2.6.4*"; then
  rm "$TARGET_DIR/hadoop-2.6.4*"

fi

tar zxvf "$TARGET_DIR/hadoop-2.6.4.tar.gz"


if "$TARGET_DIR/hadoop"; then
    rm "$TARGET_DIR/hadoop"

fi

mv "$TARGET_DIR/hadoop-2.6.4" "$TARGET_DIR/hadoop"

HADOOP_SETUP_DIR="$TARGET_DIR/hadoop/etc/hadoop"

rm -rf "$HADOOP_SETUP_DIR/mapred-site.xml.template"
rm -rf "$HADOOP_SETUP_DIR/core-site.xml"
rm -rf "$HADOOP_SETUP_DIR/yarn-site.xml"
rm -rf "$HADOOP_SETUP_DIR/hdfs-site.xml"

touch "$HADOOP_SETUP_DIR/mapred-site.xml.template"
touch "$HADOOP_SETUP_DIR/core-site.xml"
touch "$HADOOP_SETUP_DIR/yarn-site.xml"
touch "$HADOOP_SETUP_DIR/hdfs-site.xml"

# /********************************************************/
#  Hadoop map-reduce environment configuration
#
# /********************************************************/

echo "<configuration>
    <property>
        <name>mapreduce.job.tracker</name>
        <value>HD0:5431</value>
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
        <value>HD0:8025</value>
    </property>
    <property>
        <name>yarn.resourcemanager.scheduler.address</name>
        <value>HD0:8035</value>
    </property>
    <property>
        <name>yarn.resourcemanager.address</name>
        <value>HD0:8050</value>
    </property>
</configuration>" > "$HADOOP_SETUP_DIR/yarn-site.xml"

# /********************************************************/
#  Hadoop core environment configuration
#
# /********************************************************/

echo "<configuration>
    <property>
        <name>fs.default.name</name>
        <value>hdfs://HD0:9000/</value>
    </property>
    <property>
        <name>fs.default.FS</name>
        <value>hdfs://HDO:9000/</value>
    </property>

</configuration>" > "$HADOOP_SETUP_DIR/core-site.xml"

# /********************************************************/
#  Hadoop dfs environment configuration
#
# /********************************************************/
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
        <value>HD0:50070</value>
    </property>
    <property>
        <name>dfs.replication</name>
        <value>3</value>
    </property>
</configuration>" > "$HADOOP_SETUP_DIR/hdfs-site.xml"

# /********************************************************/

echo "export HADOOP_HOME=/usr/local/hadoop" >> ~/.bashrc
echo "export PATH=$PATH:$HADOOP_HOME/bin" >> ~/.bashrc
echo "export PATH=$PATH:$HADOOP_HOME/sbin" >> ~/.bashrc
echo "export HADOOP_MAPRED_HOME=$HADOOP_HOME" >> ~/.bashrc
echo "export HADOOP_COMMON_HOME=$HADOOP_HOME" >> ~/.bashrc
echo "export HADOOP_HDFS_HOME=$HADOOP_HOME" >> ~/.bashrc
echo "export YARN_HOME=$HADOOP_HOME" >> ~/.bashrc
echo "export HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native" >> ~/.bashrc
echo "export HADOOP_OPTS="-Djava.library.path=$HADOOP_HOME/lib"" >> ~/.bashrc
# -- HADOOP ENVIRONMENT VARIABLES END -- #
echo "export JAVA_HOME=/usr/lib/jvm/jdk-8-oracle-arm32-vfp-hflt/jre" >> ~/.bashrc

source ~/.bashrc

# /********************************************************/
function create_hdfs{

     if "$TARGET_DIR/hadoop_temp"; then
          rm -r "$TARGET_DIR/hadoop_temp"
     fi

     mkdir "$TARGET_DIR/hadoop_temp"
     mkdir "$TARGET_DIR/hadoop_temp/hdfs"
     mkdir "$TARGET_DIR/hadoop_temp/hdfs/datanode"

}

function change_permissions{

    chown -R $USER "$TARGET_DIR/hadoop"
    chown -R $USER "$TARGET_DIR/hadoop_temp"
}

# /********************************************************/



