#!/bin/bash

# Script to create an AMI backup of the logging servers
# Script takes a file with a list of logging server names (ec2 names) one per line, profile and region

# Start error checks
if [ $# -ne 3 ]
then
   echo "Incorrect usage ... see usage guide below "
   echo "$0 << Name of file with instance names >> << region >> << profile >> "
   exit
fi

if [ ! -f $1 ]
then
   echo "Cannot find file: $1 "
   exit
fi

filename=$1
region=$2
profile=$3
dateformat=`date "+%Y%m"`
tempfile="name-id-temp.temp"
command_file="commands.txt"
description_suffix=" logstash"
name_suffix=" backup $dateformat"

# Generate values for aws query
values=`cat $filename | xargs | sed "s/ /,/g"`

# Run command to get instance name and id
# A in A_Name and B in B_Id is used to order the output (columns) because aws output results based on alphabetical heading
# Order of the columns are important for awk later when reading values
aws_cmd="aws ec2 describe-instances --region $region --profile $profile --filters \"Name=tag:Name,Values=$values\" --query 'Reservations[].Instances[].{A_Name:Tags[?Key==\`Name\`]|[0].Value, B_Id:InstanceId}' --output text"
eval $aws_cmd > $tempfile

# Remove any previous command file
rm -f $command_file 

# Read the file with names and instance ids and generate AMI images
while read line
do
  instance_name=`echo $line | awk '{print $1}'`
  instance_id=`echo $line | awk '{print $2}'`  
  ami_cmd="aws ec2 create-image --region $region --profile $profile --instance-id $instance_id --description \"$instance_name$description_suffix\" --name \"$instance_name$name_suffix\""
echo $ami_cmd | tee -a $command_file
done < $tempfile

rm -f $tempfile
