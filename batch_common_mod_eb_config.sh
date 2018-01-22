#!/bin/bash

# Script takes a file with environment-names, 1 per line and json formatted file with options to update
# Script also takes region
# Script then does an update-environment using the json formatted file
# Easy way to get a list of environments is from eb list -a command if a lot of env are to be used

if [ $# -ne 4 ]
then
  echo "4 Arguments required"
  echo "$0 <file with env list> <json formated file with data> <region> <profile>"
  exit 3
fi

if ! [[ -f "$1" ]]
then
  echo "Env List File: $1 does not exist"
  exit 2
fi

if ! [[ -f "$2" ]]
then
  echo "Data File: $2 does not exist"
  exit 2
fi

env_list_file=$1
data_to_update=$2
region=$3
profile=$4

while read line
do
  env_name=$line
  update_cmd="aws elasticbeanstalk update-environment --region $region --profile $profile --environment-name $env_name --option-settings file://$data_to_update"
  echo $update_cmd
  echo "Enter anything to execute"
  read input < /dev/tty
  eval $update_cmd
done < $env_list_file
