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

check

systemctl enable mysqld &>>$LOG_FILE
VALIDATE $? "Enabled mysql server"

systemctl start mysqld &>>$LOG_FILE
VALIDATE $? "started mysql server"

mysql -h mysql.daws81.com -u root -pExpenseApp@1 &>>$LOG_FILE
if [ $? -ne 0 ]
then
    echo "MySQL root password is not setup...setting now" | tee -a $LOG_FILE
    mysql_secure_installation --set-root-pass ExpenseApp@1 &>>$LOG_FILE
    VALIDATE $? "SETTING ROOT PASSWORD"
else
    echo "MySQL root password is already setup....skipping" | tee -a $LOG_FILE
fi