#!/usr/bin/env python

# Script to get IP of an instance 
# The aws ec2 query gathers relevant data
# A dictionary is then made and the instance name and matching ip retrieved
# SSH connection is then establised using the IP

import json
import os
import sys
import subprocess
from os.path import expanduser
import argparse

# Setup required and optional arguments
parser = argparse.ArgumentParser()
parser.add_argument("name", help="Name of instance(s) to search for and connect to")
parser.add_argument("-r", dest="region", help="Specify non-default region")
parser.add_argument("-p", dest="profile", help="Specify a non-default AWS profile")
args = parser.parse_args()

# Check for existence of config file
cfg_file = expanduser("~/.ssh/fans_ssh_user.cfg")
if not os.path.isfile(cfg_file) :
	print ("File with user config settings not found")
	print ("Missing file: %s") %(cfg_file)
	sys.exit(1)


found_instance = 0
list_of_instances = []

# Read in default settings from config file
with open(cfg_file,'r') as f:
	user_info = json.load(f)

user_name = user_info['user_name']
region = user_info['region']
profile = user_info['profile']

# Overwrite defaults if other options were specified on command line
if args.region :
	region = args.region
if args.profile :
	profile = args.profile

instc_name = args.name

# command to filter results by instance name (wildcard matching) and "running" state and then further extract required parameters from the results to add to dictionary later
get_instc_ip = "aws ec2 describe-instances --region %s --profile %s --filters \"Name=tag:Name,Values=*%s*\" \"Name=instance-state-name,Values=running\" --query 'Reservations[*].Instances[*].{ec2_instc_name:Tags[?Key==`Name`] | [0].Value, id:InstanceId, pub:PublicIpAddress, state:State.Name}|[]'" %(region, profile, instc_name)

#print get_instc_ip

get_result = subprocess.check_output(get_instc_ip, shell=True)
data = json.loads(get_result)

# Each item in data will be a dictionary
# Each dictionary will consist of the desired values and keys created using the get_instc_ip query
# Itertate over each dictionary and add desired values to print when presenting ssh choice

#print json.dumps(data, indent=4)

for instance in data:
	if not instance['ec2_instc_name'] :
		continue

	# generate list of ssh commands and add it to the list of possible instances
	else : 
		ssh_cmd = "ssh -i ~/.ssh/id_rsa %s@%s" %(user_name, instance['pub'])
		instance_id = instance['id']
		blank = {}
		list_of_instances.append(blank)
		list_of_instances[found_instance]['instance_id'] = instance_id
		list_of_instances[found_instance]['instance_name'] = instance['ec2_instc_name']
		list_of_instances[found_instance]['ssh_cmd'] = ssh_cmd
		found_instance += 1

#print list_of_instances
if (found_instance == 0) :
	print ("instance not found")
elif (found_instance == 1) :
	print (list_of_instances[0]['ssh_cmd'])
	subprocess.call(list_of_instances[0]['ssh_cmd'],shell=True)
else:
	for x in range (0, len(list_of_instances)) :
		print ("%d - %s\t(%s)" %(x, list_of_instances[x]['instance_name'], list_of_instances[x]['instance_id']))
	choice =  input("Enter instance number to connect to ")
	while choice < 0 or choice > len(list_of_instances) -1 :
		choice = input("Choice out of range, Enter instance to connect to ")
	print (list_of_instances[choice]['ssh_cmd'])
	subprocess.call(list_of_instances[choice]['ssh_cmd'],shell=True)
