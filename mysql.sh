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



echo "the script started executed at $(date)" | tee -a $LOG_FILE
USERID=$(id -u)

if [ $USERID -ne 0 ]
then 
    echo "user has no root access please proceed with the root access" | tee -a $LOG_FILE
    exit 2
fi

dnf install mysql-server -y
VALIDATE $? "Installing MySQL server"

systemctl enable mysqld
VALIDATE $? "Enabled mysql server"

systemctl start mysqld
VALIDATE $? "started mysql server"

mysql_secure_installation --set-root-pass ExpenseApp@1
VALIDATE $? "Setting root password"