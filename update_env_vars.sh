#!/bin/bash
# script to read a file with lines of format
# VAR=VALUE there should be no space on either side of the = sign
# the value itself however can contain spaces
# it will then be converted to a json format suitable for 
# aws cli "aws elasticbeanstalk update-environment"
# format of command:
# <command> <input file> <output file> <region> <eb_environment>

if [ $# -ne 4 ]
then
  echo "4 Arguments required"
  echo "$0 <input file> <output file> <region> <eb_environment>"
  exit 3
fi

if ! [[ -f "$1" ]]
then
  echo "Input File: $1 does not exist"
  exit 2
fi

# Take care of cases where the raw file has multiple spaces between the equal sign for 
# Variable and value
tempfile="tempfile.tmp"
sed -e 's/^     //' -e 's/ \{1,\}= \{1,\}/=/' $1 > $tempfile

read_count=1
var_count=`wc -l $1 | awk ' {print $1}'`

echo "[" > $2

while read line
do
   var=`echo $line | cut -f1 -d'='`
   value=`echo $line | cut -f2- -d'='`
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
done < $tempfile

echo "]" >> $2

cat $2

echo ""
echo ""
echo "Do you want to execute: "
echo "aws elasticbeanstalk update-environment --region $3 --environment-name $4 --option-settings file://$2"
echo "y for yes"
read response

if [ $response == "y" ] || [ "$response" == "Y" ]
then
  aws elasticbeanstalk update-environment --region $3 --environment-name $4 --option-settings file://$2 
else
   echo "Exiting without update"
fi

rm $tempfile
