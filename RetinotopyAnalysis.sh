#!/bin/bash
#~ND~FORMAT~MARKDOWN~
#~ND~START~
#
# # RetinotopyAnalysis.sh
#
# ## Copyright Notice
#
# Copyright (C) 2015 The Human Connectome Project
#
# * Washington University in St. Louis
# * University of Minnesota
# * Oxford University
#
# ## Author(s)
#
# * Kendrick Kay
# * Timothy B. Brown, Neuroinformatics Research Group, Washington University in St. Louis
#
# ## Product 
#
# [Human Connectome Project][HCP] HCP Pipeline Tools
#
# ## License
#
# See the [LICENSE](https://github.com/Washington-University/Pipelines/blob/master/LICENCE.md) file
#
# ## Description
#
# TODO
#
# ## Prerequisite Installed Software
#
# TODO
#
# ## Prerequisite Environment Variables
#
# TODO
#
# <!-- References -->
# [HCP]: https://www.humanconnectome.org
#
#~ND~END~

# Setup this script such that if any command exits with a non-zero value, the script
# itself exits and does not attempt any further processing
set -e

#
# Function Description
#
#	Show version information
#
show_version() {
	local scriptName=$(basename ${0})
	echo "${scriptName}: v1.0.0"
}

#
# Function Description
#
#	Show usage information for this script
#
usage() {
	local scriptName=$(basename ${0})
	echo ""
	echo "	Perform Retinotophy Analysis ... TO BE WRITTEN"
	echo ""
	echo "	Usage: ${scriptName} <options>"
	echo ""
	echo "		[--help] : show usage information and exit with non-zero exit code"
	echo ""
	echo "		[--version] : show version information and exit with 0 exit code"
	echo ""
	echo "		[--userid=<user-id>]"
	echo "		: user login id to use for checking on submitted jobs"
	echo "		if not specified the result of the whoami command is used"
	echo ""
	echo "		--subject=<subject-id>"
	echo "		: id of subject for the data being processed"
	echo ""
	echo "		--stimulus-location-file=<path>"
	echo "		: path to stimulus location file"
	echo ""
	echo "		--image-files=<file-list>"
	echo "		: @ symbol separated list of minimally preprocessed functional \(fMRI\) image files"
	echo ""
	echo "		--offset-files=<file-list>"
	echo "		: @ symbol separated list of behavioral files from which time offsets can be obtained"
	echo ""
	echo "		Notes:"
	echo "		  1. There should be the same number of offset files specified as there are image files specified."
	echo "		  2. There should be a one-to-one correspondence between the image files and the offset files."
	echo "		     For example, if the image files are: run1.nii.gz@run2.nii.gz@run3.nii.gz, then the corresponding"
	echo "		     offset files would be specified something like: run1_info.m@run2_info.m@run3_info.m, where the"
	echo "		     run#_info.m file provides information for the run#.nii.gz file."
	echo "		  3. Missing file values for either the image files or the offset files are indicated with a literal"
	echo "		     value of EMPTY. So if, for example, there is no offset file available for the 3rd run, the "
	echo "		     image files and offset files values would be specified as:"
	echo ""
	echo "		     --image-files=run1.nii.gz@run2.nii.gz@run3.nii.gz"
	echo "		     --offset-files=run1_info.m@run2_info.m@EMPTY"
	echo ""
	echo "	Exit Status Code:"
	echo ""
	echo "		0 if help was not requested, all parameters were properly formed, and processing succeeded"
	echo "		Non-zero otherwise - malformed parameters, help requested, or processing failure was detected"
	echo ""
}

# 
# Function Description
#	Get the command line options for this script
#
# Global output variables
#	${userid} - input - user login id
#	${subject} - input - subject id
#	${stimulus_location_file} - input - file containing information about stimuli presented
#	${image_files} - input - @ symbol separated list of minimally preprocessed functional (fMRI) image files
#	${offset_files} - input - @ symbol separated list of behavioral files from which time offsets can be obtained
#
#
get_options() {
	local scriptName=$(basename ${0})
	local arguments=($@)
	
	# initialize global output variables
	unset userid
	userid=`whoami`
	unset subject
	unset stimulus_location_file
	unset image_files
	unset offset_files
	
	# parse arguments
	local index=0
	local numArgs=${#arguments[@]}
	local argument
	
	while [ ${index} -lt ${numArgs} ]; do
		argument=${arguments[index]}
		
		case ${argument} in
			--help)
				usage
				exit 1
				;;
			--version)
				show_version
				exit 0
				;;
			--userid=*)
				userid=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--subject=*)
				subject=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--stimulus-location-file=*)
				stimulus_location_file=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--image-files=*)
				image_files=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--offset-files=*)
				offset_files=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			*)
				usage
				echo "ERROR: Unrecognized Option: ${argument}"
				exit 1
				;;
		esac
	done
	
	# check required parameters
	if [ -z ${userid} ]; then
		usage
		echo "ERROR: <user-id> not specified"
		exit 1
	fi
	
	if [ -z ${subject} ]; then
		usage
		echo "ERROR: <subject-id> not specified"
		exit 1
	fi

	if [ -z ${stimulus_location_file} ]; then
		usage
		echo "ERROR: <stimulus location file> not specified"
		exit 1
	fi
	
	if [ -z ${image_files} ]; then
		usage
		echo "ERROR: <image files> not specified"
		exit 1
	fi
	
	if [ -z ${offset_files} ]; then
		usage
		echo "ERROR: <offset files> not specified"
		exit 1
	fi
	
	# report options
	echo "-- ${scriptName}: Specified Command-line Options - Start --"
	echo "   userid: ${userid}"
	echo "   subject: ${subject}"
	echo "   stimulus_location_file: ${stimulus_location_file}"
	echo "   image_files: ${image_files}"
	echo "   offset_files: ${offset_files}"
	echo "-- ${scriptName}: Specified Command-line Options - End --"
}

# 
# Function Description
#	Main processing of script
#
main() {
	# Get Command Line Options
	#
	# Global Variables Set
	#	${userid} - input - user login id
	#	${subject} - input - subject id
	#	${stimulus_location_file} - input - file containing information about stimuli presented
	#	${image_files} - input - @ symbol separated list of minimally preprocessed functional (fMRI) image files
	#	${offset_files} - input - @ symbol separated list of behavioral files from which time offsets can be obtained
	get_options $@
	
	# break specified image files into an array so they can be accessed via an index variable
	# first create a space separated list, then populate an array
	image_files_list=`echo ${image_files} | sed 's/@/ /g'`
	image_files_array=($image_files_list)
	image_files_array_length=${#image_files_array[@]}

	# break specified offset fiiles into an array so they can be accessed via an index variable
	# first create a space separated list, then populate an array
	offset_files_list=`echo ${offset_files} | sed 's/@/ /g'`
	offset_files_array=($offset_files_list)
	offset_files_array_length=${#offset_files_array[@]}
		
	# We now have the image files in an array named image_files_array. The elements of that array can be accessed
	# using the notation ${image_files_array[0]}, ${image_files_array[1]}, ${image_files_array[2]}, etc.
	# The length of the array is stored in ${image_files_array_length}

	# We now have the offset files in an array named offset_files_array. The elements of that array can be accessed
	# using the notation ${offset_files_array[0]}, ${offset_files_array[1]}, ${offset_files_array[2]}, etc.
	# The length of the array is stored in ${offset_files_array_length}

	# Verify that the two arrays are the same length
	if [[ ${image_files_array_length} -ne ${offset_files_array_length} ]] ; then
		echo "ERROR: Specified number of image files: ${image_files_array_length}"
		echo "ERROR: Specified number of offset files: ${offset_files_array_length}"
		echo "ERROR: Must have the same number of image files and offset files"
		exit 1
	fi

	# Just for demostration, show the image and offset files
	echo ""
	echo ""
	echo "Specified image and offset files"
	echo ""
	
	image_count=0
	while [ ${image_count} -lt ${image_files_array_length} ] ; do
		echo "${image_count}: ${image_files_array[image_count]}   ${offset_files_array[image_count]}"
		image_count=$(( image_count + 1 ))
	done
	
	echo ""
	echo ""
	
	#
	# TODO - this is where you put the actual work
	#









}

#
# Invoke the main function to get things started
#
main $@








