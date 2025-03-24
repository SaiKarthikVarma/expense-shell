#!/bin/bash

LOGS_FOLDER="/var/log/expense"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME-$TIMESTAMP.log"
mkdir -p $LOGS_FOLDER

R="\e[31m"
G="\e[32m"
N="\e[0m"

VALIDATE(){
    if [ $1 -ne 0 ]
    then    
        echo  -e "$2 is ... $R failed $N" | tee -a $LOG_FILE
        exit 1
    else 
        echo -e "$2 is ... $G success $N" | tee -a $LOG_FILE
    fi
}

check(){    
    dnf list installed mysql
    if [ $? -ne 0 ]
    then
        echo "mysql is not installed ...going to be installed"
        dnf install mysql-server -y &>>$LOG_FILE
        VALIDATE $? "Installing MySQL server"
    else 
        echo "mysql server is already installed"
    fi    

        

}      


echo "the script started executed at $(date)" | tee -a $LOG_FILE

USERID=$(id -u)

if [ $USERID -ne 0 ]
then 
    echo "user has no root access please proceed with the root access" | tee -a $LOG_FILE
    exit 2
fi

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "disable default node js"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "enable nodejs 20" 

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "installing node js"


id expense &>>$LOG_FILE
if [ $? -ne 0 ]
then
    echo "expense user not exits...now creating user.."
    useradd expense &>>$LOG_FILE
    VALIDATE $? "creating expense user"
else
    echo "expense user already exits...now skipping"
fi

mkdir -p /app
VALIDATE $? "creating app folder"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOG_FILE
VALIDATE $? "downloading backend application code"

cd /app
rm -rf /app/* #remove the existing code
unzip /tmp/backend.zip &>>$LOG_FILE
VALIDATE $? "extracting backend application code"

npm install &>>$LOG_FILE

cp /home/ec2-user/expense-shell/backend.service /etc/systemd/system/backend.service

#load the data befor erunning the backend

dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "installing the mysql client"

mysql -h mysql.daws81.com -uroot -pExpenseApp@1 < /app/schema/backend.sql &>>$LOG_FILE 
VALIDATE $? "schema loading"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "deamom reload"

systemctl enable backend &>>$LOG_FILE
VALIDATE $? "enabled backend"

systemctl restart backend &>>$LOG_FILE
VALIDATE $? "restart backend"
