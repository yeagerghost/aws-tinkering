#!/bin/bash

# Script to check instances on centralized users stack
# And and instances in us-east on elastic beanstalk
# Compare the list and display which ones are missing from
# The stack

eblist="eblist.txt"
ids="ec2_ids_from_eb.txt"
opswork_list="opsworkslist.txt"
missing="missing_ids.txt"

# Generate elastic beanstalk list with names and instance ids
echo "Processing elastic beanstalk list ... "
aws ec2 describe-instances --region us-east-1 --filters "Name=tag-key, Values=elasticbeanstalk:environment-name" --query Reservations[].Instances[].'{ID:InstanceId, Name:Tags[?Key==`elasticbeanstalk:environment-name`]|[0].Value}' --output text > $eblist
awk '{print $1}' $eblist | sort > $ids

# Generate instance ids from opsworks stack
echo "Processing opsworks list ... "
aws opsworks describe-instances --stack-id bf347bf1-6808-44d7-8f72-ccb0e092871f --region us-east-1 --query Instances[].Ec2InstanceId | sed -e 's/"//g' -e 's/ //g' -e 's/,//' | sort   > $opswork_list
echo ""

echo "Instances in elastic beanstalk not in opsworks ... "
diff $ids $opswork_list --new-line-format="" --unchanged-line-format="" > $missing
grep -f $missing $eblist
