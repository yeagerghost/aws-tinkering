#!/bin/bash

# This script is intended to update elastic beanstalk load balancers to use only TLS1.2
# Sript takes file with list of environment names region and profile
# Script will then update the load balancers for those environments setting them to use TLSv1.2 only for HTTPS listner

# str=$(printf "%40s")
# echo ${str// /rep}
# echoes "rep" 40 times.
# https://stackoverflow.com/questions/5349718/how-can-i-repeat-a-character-in-bash


# VARIABLES
env_list=$1
region=$2
profile=$3
lb_secure_port="443"
old_predefined_policy="ELBSecurityPolicy-2016-08" #Default policy set after a clone on elastic beanstalk
new_policy_name="TLS1-2-POLICY" #New TLS1.2 policy to which will be created from the AWS predefined TLS1.2 policy
new_reference_policy="ELBSecurityPolicy-TLS-1-2-2017-01" # AWS predefined policy with TLS1.2
save_directory="saved_settings"
formatter="#"
AWS_CMD_CLR='\033[0;96m' #CYAN
INFO_CLR='\033[1;32m' #GREEN
EXEC_CLR='\033[1;93m' #RED
NC='\033[0m' # No Color

# ERROR Checking
if [ $# -ne 3 ]
then
  echo "Incorrect number of arguments"
  echo "Format: $0 {file with env list} {aws region} {aws profile}"
  exit 1
fi

if [ ! -f $env_list ]
then
   echo "Cannot find environment list file: ($env_list) "
   exit 1
fi

mkdir -p $save_directory
rm -rf $save_directory/*

while read env_name
do
   info_text_formatter=$(printf "%40s")
   info_text=`echo ${info_text_formatter// /$formatter} Processing $env_name ${info_text_formatter// /$formatter}`   
   formatter_len=${#info_text}
   formatter_text=`printf %${formatter_len}s | tr " " "$formatter"`
   echo -e "${INFO_CLR}${formatter_text}${NC}"
   echo -e "${INFO_CLR}${info_text}${NC}"
   echo -e "${INFO_CLR}${formatter_text}${NC}"
   
   get_lb_name_cmd="aws elasticbeanstalk describe-environment-resources --region $region --profile $profile --environment-name $env_name --query EnvironmentResources.LoadBalancers[].Name --output text"
   lb_name=`eval $get_lb_name_cmd`
   lb_count=`echo $lb_name | awk '{print NF}'`
   if [ $lb_count -ne 1 ]
   then
      echo "******* An error occurred when processing the number of load balancers. Script only designed for 1 Load Balancer.  Skipping this environment ...******"
      continue
   fi

   display_listener_settings="aws elb describe-load-balancers --load-balancer-name $lb_name --region $region --profile $profile --query 'LoadBalancerDescriptions[].ListenerDescriptions[?Listener.LoadBalancerPort==\`$lb_secure_port\`]|[]'"

   # Save load balancer config before
   echo "Saving load balancer settings before ... "
   aws elb describe-load-balancers --load-balancer-name $lb_name --region $region --profile $profile > $save_directory/$env_name.before.$lb_name.json
   echo "Displaying listener settings before for port $lb_secure_port ... "
   eval "${display_listener_settings}"

   # Create new TLS1.2 policy from template
   create_new_policy_cmd="aws elb create-load-balancer-policy --load-balancer-name $lb_name --policy-name $new_policy_name --policy-type-name SSLNegotiationPolicyType --policy-attributes AttributeName=Reference-Security-Policy,AttributeValue=$new_reference_policy --region $region --profile $profile"
   echo -e "${EXEC_CLR}Executing ---> ${NC} ${AWS_CMD_CLR}$create_new_policy_cmd${NC}"
   eval "${create_new_policy_cmd}"
   echo "Waiting 2 seconds ..."
   sleep 2 

   # Get current policies set for HTTPS protocol and replace old TLS if necessary
   get_policies_cmd="aws elb describe-load-balancers --load-balancer-name $lb_name --region $region --profile $profile --query 'LoadBalancerDescriptions[].ListenerDescriptions[?Listener.LoadBalancerPort==\`$lb_secure_port\`]|[].PolicyNames' --output text"
   current_policies=`eval $get_policies_cmd`
   new_policies=`echo $current_policies | sed -e "s/$old_predefined_policy/$new_policy_name/" -e 's/ /" "/g' -e 's/^/"/' -e 's/$/"/' `
   replace_policy_cmd="aws elb set-load-balancer-policies-of-listener --load-balancer-name $lb_name --load-balancer-port $lb_secure_port --policy-names $new_policies --region $region --profile $profile"
   echo -e "${EXEC_CLR}Executing --> ${NC} ${AWS_CMD_CLR}$replace_policy_cmd${NC}"
   eval "${replace_policy_cmd}"
   echo "Waiting 2 seconds ... "
   sleep 2

   # Save load balancer config after
   echo "Saving load balancer settings after ... "
   aws elb describe-load-balancers --load-balancer-name $lb_name --region $region --profile $profile > $save_directory/$env_name.after.$lb_name.json
   echo "Displaying listener settings after for port $lb_secure_port ... "
   eval "${display_listener_settings}"

done < $env_list

echo -e "${INFO_CLR} Complete before and after load balancer settings saved in directory \"$save_directory${NC}\""
