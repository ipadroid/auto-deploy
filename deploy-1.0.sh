#!/bin/sh

################�ýű�������Ŀ���Զ�������(���ظ��´��롢����ϴ�������������)###################
echo "��ǰĿ¼��"`pwd`

#������Ŀ����
APP_COMMON=./zcfront-common/target/zcfront-common-0.0.1-SNAPSHOT.jar
APP_DAO=./zcfront-dao/target/zcfront-dao-0.0.1-SNAPSHOT.jar
APP_JOIN=./zcfront-join/target/zcfront-join-0.0.1-SNAPSHOT.jar
APP_PROVIDER=./zcfront-provider/target/zcfront-provider-0.0.1-SNAPSHOT.jar
APP_PROVIDER_CONF1=./zcfront-provider/target/classes/dsf.properties
APP_PROVIDER_CONF2=./zcfront-provider/target/classes/log4j.xml
APP_WEB=./zcfront-web/target/zcfrontweb.war
APP_TASK=./zcfront-task/target/zcfront-task.war

#��Ҫ�������ip,username,target path
#IPS="192.168.7.230 192.168.7.231"
IPS=$1
echo "################## ���ڲ���Ļ����� ip��$1 ######################"
USERNAME=dsfuser
CSC_PATH=/home/dsfuser/soft/zcfront-new-container
CSC_PROVIDER_PATH=$CSC_PATH/modules/zcfront-provider
TOMCAT_PATH=/home/dsfuser/soft/zcfront-tomcat
TEST=/home/dsfuser/soft

#1.���´���
svn up
if [ $? -eq 0 ]; then
    echo "############### ������³ɹ�����ʼmaven���...################"
    sleep 2
else
    echo "############### �������ʧ�ܣ�#################"
    exit 0
fi
#2.���
echo "################### ��ʼ����������Ի��� $2 ######################"
mvn clean package -P $2 -U -Dmaven.test.skip=true
if [ $? -eq 0 ]; then
    echo "############### ��Ŀ����ɹ�����ʼ�����...#################"
    sleep 2
else
    echo "############### ��Ŀ���ʧ�ܣ�#################"
    exit 0
fi
#3.�����
for IP in $IPS;do
    echo "############### ��ʼ�������ip��$IP ...#################"

    echo "############### �������ip��$IP ,1.ͣ����...#################"
    ##### ps -ef |grep $TOMCAT_PATH/bin | grep -v 'grep'| awk '{print $2}'
    ##### ssh -n $USERNAME@$IP "TOMID=\$(ps -ef |grep $TOMCAT_PATH | grep -v 'grep'| awk '{print \$2}');kill -9 \$TOMID;"
    #ֹͣtomcat
    TOMCAT_ID=$(ssh -n $USERNAME@$IP "ps -ef |grep $TOMCAT_PATH/bin | grep -v 'grep'| awk '{print \$2}'")
    if [ $TOMCAT_ID ]; then
        ssh -n $USERNAME@$IP "kill -9 $TOMCAT_ID"
        echo "############### �������ip��$IP ,tomcat����PID��$TOMCAT_ID ֹͣ�ɹ� #################"
        sleep 1
    else
        echo "############### �������ip��$IP ,tomcat�Ѿ�ֹͣ #################"
    fi
    
    #ֹͣcsc container
    CSC_ID=$(ssh -n $USERNAME@$IP "ps -ef |grep $CSC_PATH/conf | grep -v 'grep'| awk '{print \$2}'")
    if [ $CSC_ID ]; then
        ssh -n $USERNAME@$IP "nohup sh $CSC_PATH/bin/stop_csc.sh &"
        echo "############### �������ip��$IP ,csc container����PID��$CSC_ID ֹͣ�ɹ� #################"
        sleep 1
    else
        echo "############### �������ip��$IP ,csc container�Ѿ�ֹͣ #################"
    fi
    echo "############### �������ip��$IP ,1.ͣ������� #################"

    
    echo "############### �������ip��$IP ,2.���tomcat�еİ���ʼ... #################"
    ssh -n $USERNAME@$IP "rm -r $TOMCAT_PATH/webapps/*"
    echo "############### �������ip��$IP ,2.���tomcat�еİ����� #################"

    echo "############### �������ip��$IP ,3.�ϴ���...#################"
    scp $APP_PROVIDER $USERNAME@$IP:$CSC_PROVIDER_PATH
    scp $APP_PROVIDER_CONF1 $USERNAME@$IP:$CSC_PROVIDER_PATH/conf
    scp $APP_PROVIDER_CONF2 $USERNAME@$IP:$CSC_PROVIDER_PATH/conf
    scp $APP_JOIN $USERNAME@$IP:$CSC_PROVIDER_PATH/lib
    scp $APP_COMMON $USERNAME@$IP:$CSC_PROVIDER_PATH/lib
    scp $APP_DAO $USERNAME@$IP:$CSC_PROVIDER_PATH/lib
    scp $APP_WEB $USERNAME@$IP:$TOMCAT_PATH/webapps
    scp $APP_TASK $USERNAME@$IP:$TOMCAT_PATH/webapps
    echo "############### �������ip��$IP ,3.�ϴ������ #################"

    
    echo "############### �������ip��$IP ,4.�ϴ�����jar�� #################"
    #pcif1=../repository/com/lz/cif/pcif/pcif-api/1.0.24-SNAPSHOT/pcif-api-1.0.24-SNAPSHOT.jar
    #pcif2=../repository/com/lz/cif/pcif/pcif-domain/1.0.24-SNAPSHOT/pcif-domain-1.0.24-SNAPSHOT.jar
    #scp $pcif1 $USERNAME@$IP:$CSC_PROVIDER_PATH/lib
    #scp $pcif2 $USERNAME@$IP:$CSC_PROVIDER_PATH/lib
    echo "############### �������ip��$IP ,4.�ϴ�����jar����� #################"

    sleep 1

    echo "############### �������ip��$IP ,5.��������ʼ... #################"
    ssh -n $USERNAME@$IP "sh $TOMCAT_PATH/bin/catalina.sh start"
    sleep 2
    ssh -n $USERNAME@$IP "sh $CSC_PATH/bin/start_csc.sh > /dev/null &"
    echo "############### �������ip��$IP ,������������... #################"
    sleep 5
    echo "############### �������ip��$IP ,5.����������� #################"
done

echo "��ӡɶ��,��ȥ[$IP]����������Ƿ�����[ps aux | grep zcfront]...quickly!"
