#!/bin/bash

# Script to swap environment CNAMES | URLS
# Sript takes the profile and region
# Script generates the list of environment pairs to swap
# Script assumes environment names end with -blue and -green
# The commands for the swap are then generated

SRC_CLR='\033[0;96m' #CYAN
DEST_CLR='\033[1;32m' #GREEN
SCRIPT_CLR='\033[1;31m' #RED
NC='\033[0m' # No Color

if [ $# -ne 2 ]
then
  echo "Incorrect number of arguments"
  echo "Format: $0 <region> <profile>"
  exit
fi

region=$1
profile=$2
env_pairs="env_swap_list.txt"
suffix_1="-blue"
suffix_2="-green"
run_swap_commands="swap$suffix_1$suffix_2-$region-$profile.sh"


echo "Generating environment list pairs ..."
eb list -a --profile $profile --region $region | sort | sed -E "s/$suffix_1|$suffix_2//g" | uniq > $env_pairs
echo "========================================================" 
echo "Base Environments Found (without $suffix_1 or $suffix_2)"
echo "========================================================" 
cat $env_pairs
echo ""
echo ""

echo "#!/bin/bash -x" > $run_swap_commands
chmod 755 $run_swap_commands

while read line
do
  source_env=`echo $line$suffix_1`
  dest_env=`echo $line$suffix_2 `
  echo -e "aws elasticbeanstalk swap-environment-cnames --source-environment-name ${SRC_CLR}$source_env${NC} --destination-environment-name ${DEST_CLR}$dest_env${NC} --profile $profile --region $region"
  echo -e "aws elasticbeanstalk swap-environment-cnames --source-environment-name $source_env --destination-environment-name $dest_env --profile $profile --region $region"  >> $run_swap_commands
done < $env_pairs

echo ""
echo -e "To execute the displayed commands run the script ${SCRIPT_CLR}$run_swap_commands${NC}"
