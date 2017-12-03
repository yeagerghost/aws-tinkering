#!/usr/bin/env python

# This script will take 2 files 
# 1st with options to find -- 1 per line for each file
# 2nd -- json formated as an elstic beanstalk describe-environment format
# Purpose of script is to extract a list of options or values from the file
# This just makes it easier to search for some options from a config
# This version has the option of writing the settings to a file that can be used for upgrading env vars

# Hardcoded writeout dir as "writeout_dir"

import sys
import json
import subprocess
from sys import argv

if len(sys.argv) != 6 :
        print ("Incorrect number of arguments")
        print("Format: %s {{ file with what to search for }} << verbose|data >> << value|option >> << write|nowrite>> {{ json settings file }} " %(sys.argv[0]))
        sys.exit(1)


option_file = sys.argv[1]
style = sys.argv[2]
choice = sys.argv[3]
write_option = sys.argv[4]
settings_file = sys.argv[5]

if choice != "option" and choice != "value" :
        print("Enter \"option\" or \"value\" as a choice")
        print("Format: %s {{ file with what to search for }} << verbose|data >> << value|option >> << write|nowrite>> {{ json settings file }} " %(sys.argv[0]))
        sys.exit(1)

if style != "verbose" and style != "data" :
	print "Enter \"data\" or \"verbose\" for style"
	sys.exit(1)

if write_option != "write" and write_option != "nowrite" :
        print("Enter \"write\" or \"nowrite\" for a write option")
        print("Format: %s {{ file with what to search for }} << verbose|data >> << value|option >> << write|nowrite>> {{ json settings file }} " %(sys.argv[0]))
        sys.exit(1)

formatter = "*"
loop_count = 0
option_match_count = 0
value_match_count = 0
writeout_dir = "writeout_dir"
outputfile_prefix= "upgrade."
search_list = open(option_file).read().splitlines()
parsed_filename = settings_file.split("/")
outputfile_base = parsed_filename[ (len(parsed_filename) -1) ] 
upgrade_outputfile ="%s/%s%s" %(writeout_dir,outputfile_prefix,outputfile_base)

# print search_list


with open(settings_file) as settings_data :
	filedata = json.load(settings_data)


if choice == "option" :
	for eb_option in filedata['ConfigurationSettings'][0]['OptionSettings'] : 
		if loop_count == 0 and style == "verbose" :    # print heading only once for verbose option whether a match is found or not
	                        print "%s" %(formatter * len(settings_file))
	                        print settings_file
	                        print "%s" %(formatter * len(settings_file))

		# If OptionName is a key in the current eb option dictionary AND an item from the search_list is a substring of the actual value of the OptionName key
		if 'OptionName' in eb_option and [ item for item in search_list if item in eb_option['OptionName'] ] :
			option_match_count+=1
			if option_match_count == 1 and style == "data" :  
				# print heading only once (first match) only for data option
				print "%s" %(formatter * len(settings_file))
				print settings_file
				print "%s" %(formatter * len(settings_file))

				# open file for writing once a match is found and write option is specified
				if write_option == "write" :
					outfile_handler = open(upgrade_outputfile,'w')
					outfile_handler.write('[\n')
			matched_record = json.dumps(eb_option, indent=4)
			print "%s" %(matched_record)
			if write_option == "write" :
				outfile_handler.write(matched_record)
				outfile_handler.write(",\n")
		loop_count+=1
	if write_option == "write" and option_match_count >= 1 :
		outfile_handler.write(']\n')
		outfile_handler.close()

if choice == "value" :
	for eb_option in filedata['ConfigurationSettings'][0]['OptionSettings'] : 
		if loop_count == 0 and style == "verbose" :    # print heading only once for verbose option whether a match is found or not
	                        print "%s" %(formatter * len(settings_file))
	                        print settings_file
	                        print "%s" %(formatter * len(settings_file))

		# If Value is a key in the current eb option dictionary AND an item from the search_list is a substring of the actual value of the Value key
		# And ignore anything from with the OptionName Configdocument
		if 'Value' in eb_option and [ item for item in search_list if item in eb_option['Value'] ] and eb_option['OptionName'] != 'ConfigDocument' and eb_option['OptionName'] != 'EnvironmentVariables' :
			value_match_count+=1
			if value_match_count == 1 and style == "data" :  
				# print heading only once (first match) only for data option
				print "%s" %(formatter * len(settings_file))
				print settings_file
				print "%s" %(formatter * len(settings_file))

				# open file for writing once a match is found and write option is specified
				if write_option == "write" :
					outfile_handler = open(upgrade_outputfile,'w')
					outfile_handler.write('[\n')
			matched_record = json.dumps(eb_option, indent=4)
			print "%s" %(matched_record)
			if write_option == "write" :
				outfile_handler.write(matched_record)
				outfile_handler.write(",\n")
		loop_count+=1
	if write_option == "write" and value_match_count >= 1 :
		outfile_handler.write(']\n')
		outfile_handler.close()
