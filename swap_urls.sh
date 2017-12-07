#!/bin/bash

# Script to swap environment CNAMES | URLS
# Sript takes a file with the environment names 2 per line <source> <destination>
# 

SRC_CLR='\033[0;96m' #CYAN
DEST_CLR='\033[1;33m' #YELLOW
NC='\033[0m' # No Color

if [ $# -ne 3 ]
then
  echo "Incorrect number of arguments"
  echo "Format: $0 <file with url pairs> <region> <profile>"
  exit
fi

region=$2
profile=$3

while read line
do
  source_env=`echo $line | awk '{print $1}'`
  dest_env=`echo $line | awk '{print $2}'`
  echo -e "aws elasticbeanstalk swap-environment-cnames --source-environment-name ${SRC_CLR}$source_env ${NC} --destination-environment-name ${DEST_CLR}$dest_env ${NC} --profile $profile --region $region"
done < $1
