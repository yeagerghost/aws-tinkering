#!/bin/bash
# Convert text file in format 
# VAR=VALUE into json file for use with
# aws elasticbeanstalk update-environment
# $1 input file
# $2 output file

if [ $# -ne 2 ]
then
  echo "Incorrect number of arguments"
  echo "Format: $0 <input raw file> <output json file>"
  exit
fi

read_count=1
var_count=`wc -l $1 | awk ' {print $1}'`

echo "[" > $2

while IFS== read var value
do
   if [ $read_count -eq $var_count ]
   then
     echo "    {" >> $2
     echo "        \"OptionName\": \"$var\"," >> $2
     echo "        \"Namespace\": \"aws:elasticbeanstalk:application:environment\"," >> $2
     echo "        \"Value\": \"$value\"" >> $2
     echo "    }" >> $2
   else
     echo "    {" >> $2
     echo "        \"OptionName\": \"$var\"," >> $2
     echo "        \"Namespace\": \"aws:elasticbeanstalk:application:environment\"," >> $2
     echo "        \"Value\": \"$value\"" >> $2
     echo "    }," >> $2
   fi
   ((read_count++))   
done < $1

echo "]" >> $2

cat $2
