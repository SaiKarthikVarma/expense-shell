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

dnf install nginx -y &>>$LOG_FILE
VALIDATE $? "installing nginx"

systemctl enable nginx &>>$LOG_FILE
VALIDATE $? "enabling nginx"

systemctl start nginx &>>$LOG_FILE
VALIDATE $? "starting nginx"

rm -rf /usr/share/nginx/html/*  &>>$LOG_FILE #removing the default website
VALIDATE $? "removing default website"

curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip &>>$LOG_FILE
VALIDATE $? "downloading the frontend code"

cd /usr/share/nginx/html
unzip /tmp/frontend.zip &>>$LOG_FILE
VALIDATE $? "extracting front end code"

cp /home/ec2-user/expense-shell/expense.conf /etc/nginx/default.d/expense.conf

systemctl restart nginx