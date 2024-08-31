#!/bin/bash

LOGS_FOLDER="/var/log/expense"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME-$TIMESTAMP.log"
mkdir -p $LOGS_FOLDER


USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

CHECK_ROOT(){
    if [ $USERID -ne 0 ]
    then
      echo -e "Please run the script with $R root privileges $N" | tee -a $LOG_FILE
      exit 1
    fi  
}

VALIDATE(){
    if [ $1 -ne 0 ]
    then
      echo -e "$2 is..... $R Failed $N" | tee -a $LOG_FILE
    else
      echo -e "$2 is....... $G Success $N" | tee -a $LOG_FILE 
    fi  
}

echo "Script started executed at: $(date)" | tee -a $LOG_FILE

CHECK_ROOT

dnf install mysql-server -y &>>$LOG_FILE 
VALIDATE $? "MYSQL Server"

systemctl enable mysqld &>>$LOG_FILE 
VALIDATE $? "Enabling Mysql Service"

systemctl start mysqld &>>$LOG_FILE 
VALIDATE $? "Starting Mysql Service"

mysql -h mysql.devops81.online -u root -pExpenseApp@1 -e 'show databases;' &>>$LOG_FILE 

if [ $? -ne 0 ]
then
  echo "MYSQL root $R password is not set....Setting up now.. $N" | tee -a $LOG_FILE
  mysql_secure_installation --set-root-pass ExpenseApp@1
  VALIDATE $? "Setting up MYSQL Root Password"
else
  echo "MYSQL root $Y password is already setup nothing to do.... $N" | tee -a $LOG_FILE
fi