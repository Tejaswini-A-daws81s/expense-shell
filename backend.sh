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

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disabling nodejs"

dnf module enable nodejs:20 -y | tee -a $LOG_FILE
VLIDATE $? "Enabling nodejs:20"

dnf install nodejs -y | tee -a $LOG_FILE
VALIDATE $? "Installing nodejs"

id expense
if [ $? -ne 0 ]
then
  echo -e "Expense user doesnot exist...$G Creating user $N" | tee -a $LOG_FILE
  useradd expense
  VALIDATE $? "Creating Expense User"
else
  echo -e "Expense user already exist....$Y Skipping $N"  | tee -a $LOG_FILE

mkdir -p /app &>>$LOG_FILE
VALIDATE $? "Creating /app folder"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOG_FILE
VALIDATE $? "Downloading backend application mode"

cd /app
rm -rf /app/* # Remove old code and update new code
unzip /tmp/backend.zip &>>$LOG_FILE
VALIDATE $? "Extracting backend code"

npm install &>>$LOG_FILE
VALIDATE $? "npm Installation"

cp /home/ec2-user/expense-shell /etc/systemd/system/backend.service

dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "Installing MYSQL Client"

mysql -h mysql.devops81.online -uroot -pExpenseApp@1 < /app/schema/backend.sql &>>$LOG_FILE
VALIDATE $? "Loading Schema"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Daemon reload"

systemctl enable backend &>>$LOG_FILE
VALIDATE $? "Enable backend service"

systemctl restart backend &>>$LOG_FILE
VALIDATE $? "Restart backend service"






