# User specific environment and startup programs
export BAMBOO_HOME=/home/app1/bamboo-home
export JAVA_HOME=/home/app1/java/jdk1.6.0_14
export ANT_OPTS="-Xms16m -Xmx1088m -Djava.awt.headless=true"
export ANT_HOME=/home/app1/ant/apache-ant-1.7.1
export HOSTTYPE="x86_64"
export JBOSS_HOME=/home/app1/jboss43-8080/jboss-as
export LD_LIBRARY_PATH=$JBOSS_HOME/server/production/deploy/atao.ear/atao.war/WEB-INF/binaries
export ORACLE_BASE=/opt/oracle
export ORACLE_HOME=$ORACLE_BASE/product/10.2.0/client
export PATH=$JAVA_HOME/bin:$ANT_HOME/bin:$JBOSS_HOME/bin:$LD_LIBRARY_PATH:$PATH:$HOME/bin:$ORACLE_HOME/bin
