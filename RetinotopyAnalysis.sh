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
	echo "		--movie-files=<file-list>"
	echo "		: @ symbol separated list of movie files (QuickTime files) used as stimuli for the retinotopy task"
	echo ""
	echo "		--image-files=<file-list>"
	echo "		: @ symbol separated list of minimally preprocessed functional \(fMRI\) image files"
	echo ""
	echo "		--behavior-files=<file-list>"
	echo "		: @ symbol separated list of behavior files from which time offsets can be obtained"
	echo ""
	echo "		Notes:"
	echo ""
	echo "		  1. There should be the same number of behavior files specified as there are image files specified."
	echo ""
	echo "		  2. There should be a one-to-one correspondence between the image files and the behavior files."
	echo "		     For example, if the image files are: "
	echo ""
	echo "		       run1.nii.gz@run2.nii.gz@run3.nii.gz"
	echo ""
	echo "		     then the corresponding behavior files would be specified something like: "
	echo ""
	echo "		       run1_behavior.xml@run2_behavior.xml@run3_behavior.xml"
	echo ""
	echo "		     where the run#_behavior.xml file provides behavior information for the run#.nii.gz file."
	echo ""
	echo "		  3. Missing file values for either the image files or the behavior files should be indicated with"
	echo "		     a literal value of EMPTY. For example, if there is no behavior file available for the 3rd run,"
	echo "		     the image files and behavior files values would be specified as:"
	echo ""
	echo "		     --image-files=run1.nii.gz@run2.nii.gz@run3.nii.gz"
	echo "		     --behavior-files=run1_behavior.xml@run2_behavior.xml@EMPTY"
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
#	${movie_files} - input - @ symbol separated list of movie files (QuickTime files) used as stimuli for the 
#	                         retinotopy task
#	${image_files} - input - @ symbol separated list of minimally preprocessed functional (fMRI) image files
#	${behavior_files} - input - @ symbol separated list of behavior files from which time offsets can be obtained
#
get_options() {
	local scriptName=$(basename ${0})
	local arguments=($@)
	
	# initialize global output variables
	unset userid
	userid=`whoami`
	unset subject
	unset movie_files
	unset image_files
	unset behavior_files
	
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
			--movie-files=*)
				movie_files=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--image-files=*)
				image_files=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--behavior-files=*)
				behavior_files=${argument/*=/""}
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

	if [ -z ${movie_files} ]; then
		usage
		echo "ERROR: <movie files> not specified"
		exit 1
	fi
	
	if [ -z ${image_files} ]; then
		usage
		echo "ERROR: <image files> not specified"
		exit 1
	fi
	
	if [ -z ${behavior_files} ]; then
		usage
		echo "ERROR: <behavior files> not specified"
		exit 1
	fi
	
	# report options
	echo "-- ${scriptName}: Specified Command-line Options - Start --"
	echo "   userid: ${userid}"
	echo "   subject: ${subject}"
	echo "   movie_files: ${movie_files}"
	echo "   image_files: ${image_files}"
	echo "   behavior_files: ${behavior_files}"
	echo "-- ${scriptName}: Specified Command-line Options - End --"
}

# 
# Function Description
#	Main processing of script
#
main() {
	local scriptName=$(basename ${0})
	# Get Command Line Options
	#
	# Global Variables Set
	#	${userid} - input - user login id
	#	${subject} - input - subject id
	#	${movie_files} - input - @ symbol separated list of movie files (QuickTime files) used as stimuli for the
	#	                         retinotopy task
	#	${image_files} - input - @ symbol separated list of minimally preprocessed functional (fMRI) image files
	#	${behavior_files} - input - @ symbol separated list of behavior files from which time offsets can be obtained
	get_options $@
	
	# Break specified movie files into an array so they can be accessed via an index variable.
	# First create a space separted list, then populate an array.
	#
	# After these steps, we will have the movie file names in an array named movie_files_array. The elements of that
	# array will be accessible using the notation ${movie_files_array[0]}, ${movie_files_array[1]}, 
	# ${movie_files_array[2]}, etc. The length of the array will be stored in ${movie_files_array_length}
	movie_files_list=`echo ${movie_files} | sed 's/@/ /g'`
	movie_files_array=($movie_files_list)
	movie_files_array_length=${#movie_files_array[@]}	

	# Break specified image files into an array so they can be accessed via an index variable.
	# First create a space separated list, then populate an array.
	#
	# After these steps, we will have the image file names in an array named image_files_array. The elements of that
	# array will be accessible using the notation ${image_files_array[0]}, ${image_files_array[1]},
	# ${image_files_array[2]}, etc. The length of the array will be stored in ${image_files_array_length}
	image_files_list=`echo ${image_files} | sed 's/@/ /g'`
	image_files_array=($image_files_list)
	image_files_array_length=${#image_files_array[@]}

	# Break specified behavior files into an array so they can be accessed via an index variable.
	# First create a space separated list, then populate an array.
	#
	# After these steps, we will have the behavior file names in an array named behavior_files_array. The elements of
	# that array can be accessed using the notation ${behavior_files_array[0]}, ${behavior_files_array[1]},
	# ${behavior_files_array[2]}, etc. The length of the array will be stored in ${behavior_files_array_length}
	behavior_files_list=`echo ${behavior_files} | sed 's/@/ /g'`
	behavior_files_array=($behavior_files_list)
	behavior_files_array_length=${#behavior_files_array[@]}

	# Verify that the image_files_array and the behavior_files_array are the same length
	if [[ ${image_files_array_length} -ne ${behavior_files_array_length} ]] ; then
		echo "ERROR: Specified number of image files: ${image_files_array_length}"
		echo "ERROR: Specified number of behavior files: ${behavior_files_array_length}"
		echo "ERROR: Must have the same number of image files and behavior files"
		exit 1
	fi

	# Build the Matlab movie files specification. For logging and debugging purposes show each movie file name
	echo ""
	echo "${scriptName}: Specified movie files"
	echo ""
	
	movie_count=0
	matlab_movies_spec="movie_files = {"
	while [ ${movie_count} -lt ${movie_files_array_length} ] ; do
		spacer=""
		if [ ${movie_count} -ne "0" ] ; then
			spacer=" "
		fi
		matlab_movies_spec="${matlab_movies_spec}${spacer}'${movie_files_array[movie_count]}'"
		echo "${movie_count}: ${movie_files_array[movie_count]}"
		movie_count=$(( movie_count + 1 ))
	done
	matlab_movies_spec="${matlab_movies_spec}}"

	echo ""
	echo "${scriptName}: matlab_movies_spec: ${matlab_movies_spec}"
	
	# Build the Matlab image and behavior files specifications. For logging and debugging purposes, show each
	# image file and behavior file name
	echo ""
	echo "${scriptName}: Specified image and behavior files"
	echo ""
	
	image_count=0
	matlab_image_files_spec="image_files = {"
	matlab_behavior_files_spec="behavior_files = {"
	while [ ${image_count} -lt ${image_files_array_length} ] ; do
		spacer=""
		if [ ${image_count} -ne "0" ] ; then
			spacer=" "
		fi
		matlab_image_files_spec="${matlab_image_files_spec}${spacer}'${image_files_array[image_count]}'"
		matlab_behavior_files_spec="${matlab_behavior_files_spec}${spacer}'${behavior_files_array[image_count]}'"
		echo "${image_count}: ${image_files_array[image_count]}   ${behavior_files_array[image_count]}"
		image_count=$(( image_count + 1 ))
	done
	matlab_image_files_spec="${matlab_image_files_spec}}"
	matlab_behavior_files_spec="${matlab_behavior_files_spec}}"
	
	echo ""
	echo "${scriptName}: matlab_image_files_spec: ${matlab_image_files_spec}"
	echo "${scriptName}: matlab_behavior_files_spec: ${matlab_behavior_files_spec}"
	
	# Create Matlab input variables file
	cat <<EOF > ${subject}_matlab_variables.txt
userid = '${userid}';
subject = ${subject};
${matlab_movies_spec};
${matlab_image_files_spec};
${matlab_behavior_files_spec};
EOF

	# Run a compiled Matlab script, passing it the variables file we just created
	export MCR_CACHE_ROOT=/tmp
	export MATLAB_HOME="/export/matlab/R2012b"
	./run_RetinotopyAnalysis.sh ${MATLAB_HOME}/MCR ${subject}_matlab_variables.txt
}

#
# Invoke the main function to get things started
#
main $@








