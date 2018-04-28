#!/bin/bash

# This script will clone prod environments to prepod environments
# Script will take the following format
# clone-prod-to-preprod { file with env names } { blue2green OR green2blue  } to indicate if cloning blue to green or green to blue
# OR clone-prod-to-preprod { file with env names } { aws profile  } { aws region  } { blue2green OR green2blue  } to indicate if cloning blue to green or green to blue
# Initial version of script will use hard coded profile name and region.  These can be passed as variables later if needed
# Script requires the presence of a template file: eb-clone-template.yml

env_list=$1
clone_option=$2
#aws_profile="prod"
#aws_region="ca-central-1"
aws_profile="default"
aws_region="us-east-2"
template_file="eb-clone-template.yml"
app_search="APPLICATION-NAME"
env_search="ENVIRONMENT-NAME"
eb_config_dir=".elasticbeanstalk"
eb_config_file="$eb_config_dir/config.yml"
cname_suffix="-preprod"

# Error checking goes here
# Check for existence of file
# Check green2blue or blue2green was passed as an option
# -------------------------


mkdir -p $clone_option
cp $env_list $clone_option
cd $clone_option
echo "branch-defaults:
  default:
    environment: $env_search
    repository: null
global:
  application_name: $app_search
  default_ec2_keyname:
  default_platform:
  default_region: $aws_region
  include_git_submodules: true
  instance_profile: null
  platform_name: null
  platform_version: null
  profile: null
  sc: null
  workspace_type: Application" > $template_file
mkdir -p $eb_config_dir

if [ "$clone_option" == "green2blue" ]
then
  echo "GREEN to BLUE"
  suffix_search="-green$"
  env_suffix_replace="-blue"
fi

if [ "$clone_option" == "blue2green" ]
then
  echo "BLUE to GREEN"
  suffix_search="-blue$"
  env_suffix_replace="-green"
fi

for env_name in $(cat $env_list)
do
  app_name=`aws elasticbeanstalk describe-environments --environment-names $env_name --region $aws_region --profile $aws_profile --query Environments[].ApplicationName --output text`
  clone_name=`echo $env_name | sed "s/$suffix_search/$env_suffix_replace/"`
  clone_cname_prefix=`echo $env_name | sed "s/$suffix_search/$cname_suffix/"`
  echo ""
  echo $app_name
  echo $env_name
  echo $clone_name
  echo $clone_cname_prefix
  echo "========================"
  sed -e "s/$app_search/$app_name/" -e "s/$env_search/$env_name/" $template_file > $eb_config_file
  clone_command="eb clone $env_name -n $clone_name -c $clone_cname_prefix -nh --profile $aws_profile"
  echo $clone_command
  # eval $clone_command
done

# cd ..
# rm -rf $clone_option
