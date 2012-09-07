#!/bin/bash

################################################################################
# Puppet module creator
#
# Script to create a useful skeleton to start developing a new Puppet module
# based on a boilerplate you choose.
#
# @author Andreas Haerter <ah@bitkollektiv.org>
# @copyright 2012, Andreas Haerter
# @license Apache License 2.0 (http://www.apache.org/licenses/LICENSE-2.0)
# @link http://bitkollektiv.org/
################################################################################



################################################################################
# Configuration
################################################################################

# directory where the Puppet module boilerplates are located, without trailing
# slash!
DIR_BOILERPLATES=$(dirname "${0}")

# some placeholder strings and/or names used within the boilerplate source codes
STR_PLACEHOLDER_BOILERPLATE="boilerplate"
STR_PLACEHOLDER_AUTHORFULLNAME="John Doe"
STR_PLACEHOLDER_AUTHOREMAIL="john.doe@example.com"
STR_PLACEHOLDER_CURRENTYEAR="YYYY"
STR_PLACEHOLDER_FIXME="FIXME/TODO"



################################################################################
# DO NOT TOUCH ANYTHING BELOW THIS LINE WITHOUT KNOWING WHAT YOU ARE DOING!
################################################################################



################################################################################
# Functions
################################################################################

###
# Recursive file string replace.
#
# Handles all files within a given directory and its sub-directories. Please
# note that this function is designed to handle UTF-8 encoded files only.
#
# @param string The string being searched for ("needle").
# @param string The replacement value ("replace") that replaces found search
#        values.
# @param string Directory to search for "haystack" files.
# @param boolean Verbose flag. Controls if the function should operate silently
#        (=false, default) or not (=true).
# @return integer 0 if everything was fine, 1 if there was an error.
# @author Andreas Haerter <ah@bitkollektiv.org>
function str_rreplace() {
	# allow usage of uninitialized variables
	set +u

	# param: search
	local SEARCH="${1}"
	if [ "${SEARCH}" == "" ]
	then
		echo "Parameter is invalid: search" 1>&2
		return 1
	fi

	# param: replace
	local REPLACE="${2}"

	# param: directory
	local DIR="${3}"
	if [ "${DIR}" != "/" ]
	then
		local DIR="${DIR%/}" # strip trailing slash
	fi
	if [ ! -d "${DIR}" ]
	then
		echo "Could not access directory: '${DIR}'" 1>&2
		echo "Please place this script in the same directory as the boilerplates." 1>&2
		return 1
	fi
	
	# param: verbose
	if [ "${4}" == "true" ] # use quotes to prevent errors if undefined
	then
		local VERBOSE=true
	else
		local VERBOSE=false
	fi

	# prevent usage of uninitialized variables
	set -u

	# Change current LANG setting for following operations if needed. This is
	# done to prevent issues regarding the sed plus grep commands and the UTF-8
	# encoded files we are going to work with. Q.v. <http://j.mp/GgQMV>.
	local LANG_SAVE=${LANG} # copy current locale LANG value.
	if [[ ! "${LANG}" == *"utf8" ]] && # check if current locale is UTF-8 aware
	   [[ ! "${LANG}" == *"UTF8" ]] &&
	   [[ ! "${LANG}" == *"utf-8" ]] &&
	   [[ ! "${LANG}" == *"UTF-8" ]]
	then
		# search for an alternative...
		for RESOURCE in $(locale -a | grep "\.utf8$" | egrep "^(en|de|es|fr)_*" | sort)
		do
			LANG=${RESOURCE}
			# use it and break loop if a "favorite" (=tested) locale is present
			if [ "${RESOURCE}" == "de_CH.utf8" ] || # Linux
			   [ "${RESOURCE}" == "de_DE.utf8" ] || # Linux
			   [ "${RESOURCE}" == "en_GB.utf8" ] || # Linux
			   [ "${RESOURCE}" == "en_NZ.utf8" ] || # Linux
			   [ "${RESOURCE}" == "en_US.utf8" ] || # Linux
			   [ "${RESOURCE}" == "de_AT.UTF-8" ] || # Mac OS
			   [ "${RESOURCE}" == "de_CH.UTF-8" ] || # Mac OS
			   [ "${RESOURCE}" == "de_DE.UTF-8" ] || # Mac OS
			   [ "${RESOURCE}" == "en_AU.UTF-8" ] || # Mac OS
			   [ "${RESOURCE}" == "en_CA.UTF-8" ] || # Mac OS
			   [ "${RESOURCE}" == "en_GB.UTF-8" ] || # Mac OS
			   [ "${RESOURCE}" == "en_IE.UTF-8" ] || # Mac OS
			   [ "${RESOURCE}" == "en_NZ.UTF-8" ] || # Mac OS
			   [ "${RESOURCE}" == "en_US.UTF-8" ]    # Mac OS
			then
				LANG=${RESOURCE}
				break
			fi
		done
		unset RESOURCE
		# check if we found something useful...
		if [[ ! "${LANG}" == *"utf8" ]] &&
		   [[ ! "${LANG}" == *"UTF8" ]] &&
		   [[ ! "${LANG}" == *"utf-8" ]] &&
		   [[ ! "${LANG}" == *"UTF-8" ]]
		then
			LANG=${LANG_SAVE} # restore LANG
			echo "Current locale is not UTF-8 aware: '${LANG}'" 1>&2
			return 1
		fi
	fi

	# inform user
	if [ ${VERBOSE} == true ]
	then
		echo -e "\033[1mReplacing '${SEARCH}' with '${REPLACE}'\033[0m"
	fi

	# let's work
	local TOUCHED=false
	local IFS_SAVE=${IFS} # copy current IFS (Internal Field Separator)
	IFS=$'\n'
	for RESOURCE in $(grep -R "${SEARCH}" "${DIR}" | cut -d ":" -f 1 -s | sort | uniq)
	do
		if [[ "${OSTYPE}" == *"darwin"* ]] || # Mac OS is using BSD sed
		   [[ "${OSTYPE}" == *"freebsd"* ]]
		then
			sed -i "" -e "s/${SEARCH}/${REPLACE}/g" "${RESOURCE}" # BSD style
		else
			sed -i -e "s/${SEARCH}/${REPLACE}/g" "${RESOURCE}" # GNU style
		fi
		if [ $? -ne 0 ]
		then
			echo "Replacing '${SEARCH}' with '${REPLACE}' in '${RESOURCE}' failed." 1>&2
			LANG=${LANG_SAVE} # restore LANG
			return 1
		elif [ ${VERBOSE} == true ]
		then
			echo "Changed: '${RESOURCE}'"
		fi
		local TOUCHED=true
	done
	IFS=${IFS_SAVE} # restore IFS (Internal Field Separator)

	if [ ${VERBOSE} == true ] &&
	   [ ${TOUCHED} == false ]
	then
		echo "Nothing to replace, no file contains '${SEARCH}'".
	fi

	echo -e "\033[32mDone.\033[0m"
	LANG=${LANG_SAVE} # restore LANG
	return 0
}


###
# User data collection wizard
#
# @return void
# @author Andreas Haerter <ah@bitkollektiv.org>
function wizard_start() {
	wizard_step1_boilerplatetype
	wizard_step2_newmodname
	wizard_step3_targetdir
	wizard_step4_authorfullname
	wizard_step5_authoremail
	# show overview about the collected data (unless everything was set by parameters)
	if [ "${OPTION_AUTHORFULLNAME}" == "" ] ||
	   [ "${OPTION_BOILERPLATE}" == "" ] ||
	   [ "${OPTION_AUTHOREMAIL}" == "" ] ||
	   [ "${OPTION_NEWMODNAME}" == "" ] ||
	   [ "${OPTION_TARGETDIR}" == "" ]
	then
		DATA_OK="n" #init
		clear
		echo "###############################################################################"
		echo "# Puppet module creator: data overview"
		echo "###############################################################################"
		echo -e "\033[1mBoilerplate source:\033[0m"
		echo "${SOURCEDIR}"
		echo ""
		echo -e "\033[1mNew module will be created in:\033[0m"
		echo "${TARGETDIR}"
		echo ""
		echo -e "\033[1mAuthor/creator of the new module:\033[0m"
		echo "${AUTHORFULLNAME} <${AUTHOREMAIL}>"
		echo ""
		echo -n "Is this correct? [y|n]: "
		read DATA_OK
		while [ ! "${DATA_OK}" == "y" ] &&
			  [ ! "${DATA_OK}" == "Y" ] &&
			  [ ! "${DATA_OK}" == "j" ] &&
			  [ ! "${DATA_OK}" == "J" ]
		do
			EXITPROG="n" #init
			echo -n "Exit program? [y|n]: "
			read EXITPROG
			if [ "${EXITPROG}" == "y" ] ||
			   [ "${EXITPROG}" == "Y" ] ||
			   [ "${EXITPROG}" == "j" ] ||
			   [ "${EXITPROG}" == "J" ]
			then
				echo "Operation canceled by user"
				echo ""
				exit 0
			fi
			# once more with feeling...
			clear
			wizard_step1_boilerplatetype
			wizard_step2_newmodname
			wizard_step3_targetdir
			wizard_step4_authorfullname
			wizard_step5_authoremail
			clear
			echo "###############################################################################"
			echo "# Puppet module creator: data overview"
			echo "###############################################################################"
			echo -e "\033[1mBoilerplate source:\033[0m"
			echo "${SOURCEDIR}"
			echo ""
			echo -e "\033[1mNew module will be created in:\033[0m"
			echo "${TARGETDIR}"
			echo ""
			echo -e "\033[1mAuthor/creator of the new module:\033[0m"
			echo "${AUTHORFULLNAME} <${AUTHOREMAIL}>"
			echo ""
			echo -n "Is this correct? [y|n]: "
			read DATA_OK
		done
	fi
	unset DATA_OK
}


###
# Let the user decide which type of boilerplate we are going to use
#
# This function is setting the global SOURCEDIR var. It is a helper of the
# wizard_start function.
#
# @return integer 0 if everything was fine, 1 if there was an error.
# @author Andreas Haerter <ah@bitkollektiv.org>
function wizard_step1_boilerplatetype() {
	echo ""
	echo "Please choose the type of boilerplate to use for the new module by typing the"
	echo "corresponding number:"
	echo ""
	SOURCEDIR="" # init the global var this wizard is for

	local CHOICE="none" #init
	local INDEX=0 # init
	local IFS_SAVE=${IFS} # copy current IFS (Internal Field Separator)
	IFS=$'\n'
	for RESOURCE in $(find "${DIR_BOILERPLATES}" -maxdepth 1 -type d -not -name "\.git" -not -name "\.hg" | sort)
	do
		# sort-out non-boilerplate directories
		if [ "${RESOURCE}" == "${DIR_BOILERPLATES}" ] || # containing dir itself
		   [ ! -f "${RESOURCE}/manifests/init.pp" ]
		then
			continue 1
		fi

		# show
		local BASENAME=$(basename "${RESOURCE}")
		echo -e "  \033[1m${INDEX}: ${BASENAME}\033[0m"
		if [ -f "${RESOURCE}/DESCRIPTION" ]
		then
			for LINE in $(cat "${RESOURCE}/DESCRIPTION")
			do
				if [ ${INDEX} -lt 10 ]
				then
					echo -n "     "
				else
					echo -n "      "
				fi
				echo ${LINE}
			done
			unset LINE
		fi
		echo ""

		# pre-select boilerplate if parameter was specified
		if [ "${OPTION_BOILERPLATE}" == "${BASENAME}" ]
		then
			local CHOICE=${INDEX}
		fi

		# store
		local LIST[${INDEX}]=${RESOURCE}
		let INDEX=${INDEX}+1
	done
	unset RESOURCE
	unset BASENAME
	unset INDEX
	IFS=${IFS_SAVE} # restore IFS (Internal Field Separator)
	unset IFS_SAVE

	set +u # allow usage of uninitialized variables
	if [ ${#LIST[@]} -eq 0 ]
	then
		echo "" 1>&2
		echo "Could not find any boilerplates in '${DIR_BOILERPLATES}'." 1>&2
		exit 1
	elif [ ${#LIST[@]} -eq 1 ]
	then
		echo ""
		echo "There is only one boilerplate, therefore nothing to choose."
		echo -n "Using "
		basename "${LIST[0]}"
		local CHOICE=0
	elif [ "${CHOICE}" != "none" ]
	then
		echo ""
		echo "Boilerplate to use was specified by parameter."
		echo -n "Using "
		basename "${LIST[${CHOICE}]}"
	else
		if [ "${OPTION_BOILERPLATE}" != "" ] &&
		   [ "${CHOICE}" == "none" ]
		then
			OPTION_BOILERPLATE=""
			echo "-b: invalid value, ignoring it." 1>&2
		fi
		echo "See http://j.mp/JVPxKL for example modules based on the different boilerplates."
		echo -n "Number identifying the boilerplate to use? "
		read CHOICE
		local CHOICE_OK=false
		while [ ${CHOICE_OK} != true ]
		do
			if [ "${CHOICE}" == "" ] ||
			   [[ ! "${CHOICE}" =~ ^[0-9]*$ ]] ||
			   [ "${LIST[${CHOICE}]}" == "" ]
			then
				echo -n "Invalid, try again: "
				read CHOICE
				continue 1
			else
				local CHOICE_OK=true
				break 1
			fi
		done
		# clean up
		unset CHOICE_OK
	fi
	SOURCEDIR=${LIST[${CHOICE}]} # var we need to process the module creation
	unset LIST
	unset CHOICE
	set -u # prevent usage of uninitialized variables
	return 0
}


###
# Let the user set the name of the new module
#
# This function is setting the global NEWMODNAME var. It is a helper of the
# wizard_start function.
#
# @return integer 0 if everything was fine, 1 if there was an error.
# @author Andreas Haerter <ah@bitkollektiv.org>
function wizard_step2_newmodname() {
	NEWMODNAME="" # init the global var this wizard is for
	if [ "${OPTION_NEWMODNAME}" != "" ]
	then
		echo ""
		echo "Name of the new module was specified by parameter."
		echo "Using '${OPTION_NEWMODNAME}'."
		NEWMODNAME=${OPTION_NEWMODNAME}
	else
		# inform user about the naming rules, cf. http://j.mp/xuM3Rr and http://j.mp/wZ8quk
		echo ""
		echo ""
		echo "NOTE: module names are restricted to lowercase alphanumeric characters and"
		echo "      underscores, and should begin with a lowercase letter; that is, they"
		echo "      have to match the pattern '^[a-z][a-z0-9_]*$'"
		echo ""
		echo -n "Please enter the name for the new module: "
		read NEWMODNAME
		local NEWMODNAME_OK=false
		while [ ${NEWMODNAME_OK} != true ]
		do
			if [ "${NEWMODNAME}" == "" ] ||
			   [[ ! "${NEWMODNAME}" =~ ^[a-z][a-z0-9_]*$ ]] # don't forget to update the parameter check if you change something here!
			then
				echo -n "Invalid, try again: "
				read NEWMODNAME
				continue 1
			else
				local NEWMODNAME_OK=true
				break 1
			fi
		done
	fi
	return 0
}


###
# Let the user decide where to put the new module
#
# This function is setting the global TARGETDIR var. It is a helper of the
# wizard_start function.
#
# @return integer 0 if everything was fine, 1 if there was an error.
# @author Andreas Haerter <ah@bitkollektiv.org>
function wizard_step3_targetdir() {
	TARGETDIR="" # init the global var this wizard is for
	if [ "${OPTION_TARGETDIR}" != "" ]
	then
		echo ""
		echo "Target directory in which the module shall be copied was specified by parameter."
		echo "Using '${OPTION_TARGETDIR}'."
		TARGETDIR=${OPTION_TARGETDIR}
	else
		echo ""
		echo "Please enter the target directory in which the module shall be copied"
		echo -n "to (just press [ENTER] for '${HOME}'):"
		read TARGETDIR
		if [ "${TARGETDIR}" != "/" ]
		then
			TARGETDIR="${TARGETDIR%/}" # strip trailing slash
		fi
		TARGETDIR_OK=false
		while [ ${TARGETDIR_OK} != true ]
		do
			if [ "${TARGETDIR}" == "" ]
			then
				# use home of current user if user just pressed [ENTER]
				TARGETDIR=${HOME}
			fi
			# don't forget to update the parameter checks if you change something here!
			if [ ! -d "${TARGETDIR}" ]
			then
				echo -n "Could not access target, try again: "
				read TARGETDIR
				if [ "${TARGETDIR}" != "/" ]
				then
					TARGETDIR="${TARGETDIR%/}" # strip trailing slash
				fi
				continue 1
			elif [ -d "${TARGETDIR}/${NEWMODNAME}" ]
			then
				echo "'${TARGETDIR}/${NEWMODNAME}' is already existing."
				echo -n "Target invalid, try again: "
				read TARGETDIR
				if [ "${TARGETDIR}" != "/" ]
				then
					TARGETDIR="${TARGETDIR%/}" # strip trailing slash
				fi
				continue 1
			else
				local TARGETDIR_OK=true
				break 1
			fi
		done
	fi
	TARGETDIR="${TARGETDIR}/${NEWMODNAME}"
	return 0
}


###
# Let the user set the authors name
#
# This function is setting the global AUTHORFULLNAME var. It is a helper of the
# wizard_start function.
#
# @return integer 0 if everything was fine, 1 if there was an error.
# @author Andreas Haerter <ah@bitkollektiv.org>
function wizard_step4_authorfullname() {
	AUTHORFULLNAME="" # init the global var this wizard is for
	if [ "${OPTION_AUTHORFULLNAME}" != "" ]
	then
		echo ""
		echo "Name of the author was specified by parameter."
		echo "Using '${OPTION_AUTHORFULLNAME}'."
		AUTHORFULLNAME=${OPTION_AUTHORFULLNAME}
	else
		echo ""
		if [ "${ENV_AUTHORFULLNAME}" == "" ]
		then
			echo -n "Please enter your full name (source code author info): "
		else
			echo "Please enter your full name (source code author info, just press [ENTER]"
			echo -n "for '${ENV_AUTHORFULLNAME}'): "
		fi
		read AUTHORFULLNAME
		AUTHORFULLNAME_OK=false
		while [ ${AUTHORFULLNAME_OK} != true ]
		do
			if [ "${AUTHORFULLNAME}" == "" ] &&
			   [ "${ENV_AUTHORFULLNAME}" == "" ]
			then
				echo -n "Invalid, try again: "
				read AUTHORFULLNAME
				continue 1
			elif [ "${AUTHORFULLNAME}" == "" ] &&
			     [ "${ENV_AUTHORFULLNAME}" != "" ]
			then
				# use environment variable if user just pressed [ENTER]
				AUTHORFULLNAME=${ENV_AUTHORFULLNAME}
			else
				local AUTHORFULLNAME_OK=true
				break 1
			fi
		done
	fi
	return 0
}


###
# Let the user set the email address of the author
#
# This function is setting the global AUTHOREMAIL var. It is a helper of the
# wizard_start function.
#
# @return integer 0 if everything was fine, 1 if there was an error.
# @author Andreas Haerter <ah@bitkollektiv.org>
function wizard_step5_authoremail() {
	AUTHOREMAIL="" # init the global var this wizard is for
	if [ "${OPTION_AUTHOREMAIL}" != "" ]
	then
		echo ""
		echo "Email address of the author was specified by parameter."
		echo "Using '${OPTION_AUTHOREMAIL}'."
		AUTHOREMAIL=${OPTION_AUTHOREMAIL}
	else
		echo ""
		if [ "${ENV_AUTHOREMAIL}" == "" ]
		then
			echo -n "Please enter your email address (source code author info): "
		else
			echo "Please enter your email address (source code author info, just press [ENTER]"
			echo -n "for '${ENV_AUTHOREMAIL}'): "
		fi
		read AUTHOREMAIL
		AUTHOREMAIL_OK=false
		while [ ${AUTHOREMAIL_OK} != true ]
		do
			if ([ "${AUTHOREMAIL}" == "" ] &&
			    [ "${ENV_AUTHOREMAIL}" == "" ]) ||
			   ([ "${AUTHOREMAIL}" != "" ] &&
			    [[ "${AUTHOREMAIL}" != *"@"* ]]) # don't forget to update the parameter and environment variable check if you change something here!
			then
				echo -n "Invalid, try again: "
				read AUTHOREMAIL
				continue 1
			elif [ "${AUTHOREMAIL}" == "" ] &&
			     [ "${ENV_AUTHOREMAIL}" != "" ]
			then
				# use environment variable if user just pressed [ENTER]
				AUTHOREMAIL=${ENV_AUTHOREMAIL}
			else
				local AUTHOREMAIL_OK=true
				break 1
			fi
		done
	fi
	return 0
}


###
# User data collection wizard
#
# @return void
# @author Andreas Haerter <ah@bitkollektiv.org>
function repowizard_start() {
	repowizard_step1_service
	repowizard_step2_remotename
	repowizard_step3_credentials
	repowizard_step4_repoaccess
	# show overview about the collected data (unless everything was set by parameters)
	if [ "${OPTION_REPOHOSTINGSERVICE}" == "" ] ||
	   [ "${OPTION_REPOHOSTINGSERVICEPROJECTNAME}" == "" ] ||
	   [ "${OPTION_REPOHOSTINGSERVICEUSERNAME}" == "" ] ||
	   [ "${OPTION_REPOHOSTINGSERVICEPWD}" == "" ] ||
	   [ "${OPTION_REPOHOSTINGSERVICEREPOACCESS}" == "" ]
	then
		DATA_OK="n" #init
		clear
		echo "###############################################################################"
		echo "# Puppet module creator: DVCS repository wizard data overview"
		echo "###############################################################################"
		echo -e "\033[1mRepository hosting service:\033[0m"
		echo "${REPOHOSTINGSERVICE}"
		echo ""
		echo -e "\033[1mRepository/project name:\033[0m"
		echo "${REPOHOSTINGSERVICEPROJECTNAME}"
		echo ""
		echo -e "\033[1mUsername:\033[0m"
		echo "${REPOHOSTINGSERVICEUSERNAME} (password not shown for security reasons)"
		echo ""
		if [ "${REPOHOSTINGSERVICE}" == "github" ] ||
		   [ "${REPOHOSTINGSERVICE}" == "bitbucket" ]
		then
			if [ "${REPOHOSTINGSERVICE}" == "github" ]
			then
				echo -e "\033[1mOrganization:\033[0m"
			else
				echo -e "\033[1mTeam:\033[0m"
			fi
			if [ "${REPOHOSTINGSERVICEORGANIZATION}" == "" ]
			then
				echo "(none)"
			else
				echo "${REPOHOSTINGSERVICEORGANIZATION}"
			fi
			echo ""
		fi
		echo -e "\033[1mRepository access:\033[0m"
		echo "${REPOHOSTINGSERVICEREPOACCESS}"
		echo ""
		echo -n "Is this correct? [y|n]: "
		read DATA_OK
		while [ ! "${DATA_OK}" == "y" ] &&
			  [ ! "${DATA_OK}" == "Y" ] &&
			  [ ! "${DATA_OK}" == "j" ] &&
			  [ ! "${DATA_OK}" == "J" ]
		do
			EXITPROG="n" #init
			echo -n "Exit program? [y|n]: "
			read EXITPROG
			if [ "${EXITPROG}" == "y" ] ||
			   [ "${EXITPROG}" == "Y" ] ||
			   [ "${EXITPROG}" == "j" ] ||
			   [ "${EXITPROG}" == "J" ]
			then
				echo ""
				echo "Repository creation canceled by user. However, have fun with your new"
				echo "Puppet module."
				echo ""
				exit 0
			fi
			# once more with feeling...
			clear
			repowizard_step1_service
			repowizard_step2_remotename
			repowizard_step3_credentials
			repowizard_step4_repoaccess
			clear
			echo "###############################################################################"
			echo "# Puppet module creator: DVCS repository wizard data overview"
			echo "###############################################################################"
			echo -e "\033[1mRepository hosting service:\033[0m"
			echo "${REPOHOSTINGSERVICE}"
			echo ""
			echo -e "\033[1mRepository/project name:\033[0m"
			echo "${REPOHOSTINGSERVICEPROJECTNAME}"
			echo ""
			echo -e "\033[1mUsername:\033[0m"
			echo "${REPOHOSTINGSERVICEUSERNAME} (password not shown for security reasons)"
			echo ""
			if [ "${REPOHOSTINGSERVICE}" == "github" ] ||
			   [ "${REPOHOSTINGSERVICE}" == "bitbucket" ]
			then
				if [ "${REPOHOSTINGSERVICE}" == "github" ]
				then
					echo -e "\033[1mOrganization:\033[0m"
				else
					echo -e "\033[1mTeam:\033[0m"
				fi
				if [ "${REPOHOSTINGSERVICEORGANIZATION}" == "" ]
				then
					echo "(none)"
				else
					echo "${REPOHOSTINGSERVICEORGANIZATION}"
				fi
				echo ""
			fi
			echo -e "\033[1mRepository access:\033[0m"
			echo "${REPOHOSTINGSERVICEREPOACCESS}"
			echo ""
			echo -n "Is this correct? [y|n]: "
			read DATA_OK
		done
	fi
	unset DATA_OK
}


###
# Let the user decide which repository hosting service he want to use
#
# This function is setting the global REPOHOSTINGSERVICE var. It is a helper of
# the repowizard_start function.
#
# @return integer 0 if everything was fine, 1 if there was an error.
# @author Andreas Haerter <ah@bitkollektiv.org>
function repowizard_step1_service() {
	echo ""
	echo "Please choose the service you want to use to host the repository for your"
	echo "new module by typing the corresponding number:"
	echo ""
	REPOHOSTINGSERVICE="" # init the global var this wizard is for

	local CHOICE="none" #init
	local INDEX=0 # init
	local IFS_SAVE=${IFS} # copy current IFS (Internal Field Separator)
	IFS=$';'
	local SERVICES="Bitbucket;GitHub"
	for SERVICE in ${SERVICES}
	do
		# show
		echo -n "- ${INDEX}: "
		echo "${SERVICE}"

		# pre-select service if parameter was specified
		SERVICE_LOWER=$(echo -n ${SERVICE} | tr A-Z a-z) #lowercase with TR
		OPTION_REPOHOSTINGSERVICE_LOWER=$(echo -n ${OPTION_REPOHOSTINGSERVICE} | tr A-Z a-z) #lowercase with TR
		if [ "${OPTION_REPOHOSTINGSERVICE_LOWER}" == "${SERVICE_LOWER}" ] &&
		   [ "${OPTION_REPOHOSTINGSERVICE_LOWER}" != "" ]
		then
			local CHOICE=${INDEX}
		fi

		# store
		local LIST[${INDEX}]=${SERVICE_LOWER}
		let INDEX=${INDEX}+1
	done
	unset SERVICE
	unset INDEX
	IFS=${IFS_SAVE} # restore IFS (Internal Field Separator)
	unset IFS_SAVE

	set +u # allow usage of uninitialized variables
	if [ ${#LIST[@]} -eq 0 ]
	then
		echo "" 1>&2
		echo "Could not find any repository hosting services." 1>&2
		exit 1
	elif [ ${#LIST[@]} -eq 1 ]
	then
		echo ""
		echo "There is only one repository hosting service, therefore nothing to choose."
		echo -n "Using ${LIST[0]}"
		local CHOICE=0
	elif [ "${CHOICE}" != "none" ]
	then
		echo ""
		echo "Repository hosting service to use was specified by parameter."
		echo "Using ${LIST[${CHOICE}]}"
	else
		echo ""
		if [ "${OPTION_REPOHOSTINGSERVICE}" != "" ] &&
		   [ "${CHOICE}" == "none" ]
		then
			OPTION_REPOHOSTINGSERVICE=""
			echo "-s: invalid value, ignoring it." 1>&2
		fi
		echo -n "Number identifying the repository hosting service to use? "
		read CHOICE
		local CHOICE_OK=false
		while [ ${CHOICE_OK} != true ]
		do
			if [ "${LIST[${CHOICE}]}" == "" ] ||
			   [ "${CHOICE}" == "" ] ||
			   [[ ! "${CHOICE}" =~ ^[0-9]*$ ]]
			then
				echo -n "Invalid, try again: "
				read CHOICE
				continue 1
			else
				local CHOICE_OK=true
				break 1
			fi
		done
		# clean up
		unset CHOICE_OK
	fi
	REPOHOSTINGSERVICE=${LIST[${CHOICE}]} # var we need to process the repo creation
	unset LIST
	unset CHOICE
	set -u # prevent usage of uninitialized variables
	return 0
}


###
# Let the user set the name of the new remote repository ("project name")
#
# This function is setting the global REPOHOSTINGSERVICEPROJECTNAME var. It is
# a helper of the repowizard_start function.
#
# @return integer 0 if everything was fine, 1 if there was an error.
# @author Andreas Haerter <ah@bitkollektiv.org>
function repowizard_step2_remotename() {
	REPOHOSTINGSERVICEPROJECTNAME="" # init the global var this wizard is for
	if [ "${OPTION_REPOHOSTINGSERVICEPROJECTNAME}" != "" ]
	then
		echo ""
		echo "Name of the new remote repository was specified by parameter."
		echo "Using '${OPTION_REPOHOSTINGSERVICEPROJECTNAME}'."
		REPOHOSTINGSERVICEPROJECTNAME=${OPTION_REPOHOSTINGSERVICEPROJECTNAME}
	else
		REPOHOSTINGSERVICEPROJECTNAME_DEFAULT="puppet-module-${NEWMODNAME}"
		echo ""
		echo ""
		echo "NOTE: most hosting services are restricting their project names alphanumeric"
		echo "      characters, underscores and minus; that is, they have to match the"
		echo "      pattern '^[a-zA-Z0-9_\-]*$'"
		echo ""
		echo    "Please enter the name for your new ${REPOHOSTINGSERVICE} project (just press [ENTER]"
		echo -n "for '${REPOHOSTINGSERVICEPROJECTNAME_DEFAULT}'): "
		read REPOHOSTINGSERVICEPROJECTNAME
		local REPOHOSTINGSERVICEPROJECTNAME_OK=false
		while [ ${REPOHOSTINGSERVICEPROJECTNAME_OK} != true ]
		do
			if [ "${REPOHOSTINGSERVICEPROJECTNAME}" == "" ]
			then
				# use defual if user just pressed [ENTER]
				REPOHOSTINGSERVICEPROJECTNAME=${REPOHOSTINGSERVICEPROJECTNAME_DEFAULT}
			fi
			if [[ ! "${REPOHOSTINGSERVICEPROJECTNAME}" =~ ^[a-zA-Z0-9_\-]*$ ]] # don't forget to update the parameter check if you change something here!
			then
				echo -n "Invalid, try again: "
				read REPOHOSTINGSERVICEPROJECTNAME
				continue 1
			else
				local REPOHOSTINGSERVICEPROJECTNAME_OK=true
				break 1
			fi
		done
	fi
	return 0
}


###
# Let the user set the credentials needed to log into the hosting service to
# create the new remote repository/project
#
# This function is setting the global REPOHOSTINGSERVICEUSERNAME,
# REPOHOSTINGSERVICEPWD and REPOHOSTINGSERVICEORGANIZATION var. It is a helper
# of the repowizard_start function.
#
# @return integer 0 if everything was fine, 1 if there was an error.
# @author Andreas Haerter <ah@bitkollektiv.org>
function repowizard_step3_credentials() {
	# username
	REPOHOSTINGSERVICEUSERNAME="" # init the global var this wizard is for
	if [ "${OPTION_REPOHOSTINGSERVICEUSERNAME}" != "" ]
	then
		echo ""
		echo "Username to authenticate you on the repository hosting service was specified"
		echo "by parameter."
		echo "Using '${OPTION_REPOHOSTINGSERVICEUSERNAME}'."
		REPOHOSTINGSERVICEUSERNAME=${OPTION_REPOHOSTINGSERVICEUSERNAME}
	else
		echo ""
		echo -n "Please enter the username to use to authenticate you on ${REPOHOSTINGSERVICE}: "
		read REPOHOSTINGSERVICEUSERNAME
		local REPOHOSTINGSERVICEUSERNAME_OK=false
		while [ ${REPOHOSTINGSERVICEUSERNAME_OK} != true ]
		do
			if [ "${REPOHOSTINGSERVICEUSERNAME}" == "" ]
			then
				echo -n "Invalid, try again: "
				read REPOHOSTINGSERVICEUSERNAME
				continue 1
			else
				local REPOHOSTINGSERVICEUSERNAME_OK=true
				break 1
			fi
		done
	fi

	# password
	REPOHOSTINGSERVICEPWD="" # init the global var this wizard is for
	if [ "${OPTION_REPOHOSTINGSERVICEPWD}" != "" ]
	then
		echo ""
		echo "Password to authenticate you on the repository hosting service was specified"
		echo "by parameter."
		echo "Using '(password not shown for security reasons)'."
		REPOHOSTINGSERVICEPWD=${OPTION_REPOHOSTINGSERVICEPWD}
	else
		echo ""
		echo    "Please enter the password belonging your username to authenticate you"
		echo -n "on ${REPOHOSTINGSERVICE} (won't be shown for security reasons): "
		stty -echo
		read REPOHOSTINGSERVICEPWD
		stty echo
		echo ""
		local REPOHOSTINGSERVICEPWD_OK=false
		while [ ${REPOHOSTINGSERVICEPWD_OK} != true ]
		do
			if [ "${REPOHOSTINGSERVICEPWD}" == "" ]
			then
				echo -n "Invalid, try again: "
				stty -echo
				read REPOHOSTINGSERVICEPWD
				stty echo
				echo ""
				continue 1
			else
				local REPOHOSTINGSERVICEPWD_OK=true
				break 1
			fi
		done
	fi

	# organization
	REPOHOSTINGSERVICEORGANIZATION="" # init the global var this wizard is for
	if [ "${REPOHOSTINGSERVICE}" == "github" ]
	then
		if [ "${OPTION_REPOHOSTINGSERVICEORGANIZATION}" != "" ]
		then
			echo ""
			echo "GitHub Organization your user belongs to was specified by parameter."
			echo "Using '${OPTION_REPOHOSTINGSERVICEORGANIZATION}'."
			REPOHOSTINGSERVICEORGANIZATION=${OPTION_REPOHOSTINGSERVICEORGANIZATION}
		else
			echo ""
			echo "GitHub provides organizations (see http://j.mp/d2PFSw for information). If"
			echo "you want to create the new repository in the organization's account instead"
			echo "of your personal one, you can enter the organization name here. Leave blank"
			echo "for none."
			echo ""
			echo -n "Please enter the GitHub organization (press [ENTER] if none): "
			read REPOHOSTINGSERVICEORGANIZATION
			local REPOHOSTINGSERVICEORGANIZATION_OK=false
			while [ ${REPOHOSTINGSERVICEORGANIZATION_OK} != true ]
			do
				if [[ ! "${REPOHOSTINGSERVICEORGANIZATION}" =~ ^[a-zA-Z][a-zA-Z0-9\-]*$ ]] && # don't forget to update the parameter check if you change something here!
				   [ "${REPOHOSTINGSERVICEORGANIZATION}" != "" ]
				then
					echo -n "Invalid, try again: "
					read REPOHOSTINGSERVICEORGANIZATION
					continue 1
				else
					local REPOHOSTINGSERVICEORGANIZATION_OK=true
					break 1
				fi
			done
		fi
	elif [ "${REPOHOSTINGSERVICE}" == "bitbucket" ]
	then
		if [ "${OPTION_REPOHOSTINGSERVICEORGANIZATION}" != "" ]
		then
			echo ""
			echo "Bitbucket Team your user belongs to was specified by parameter."
			echo "Using '${OPTION_REPOHOSTINGSERVICEORGANIZATION}'."
			REPOHOSTINGSERVICEORGANIZATION=${OPTION_REPOHOSTINGSERVICEORGANIZATION}
		else
			echo ""
			echo "Bitbucket provides teams (see http://j.mp/LHiSK9 for information). If"
			echo "you want to create the new repository in the teams's account instead"
			echo "of your personal one, you can enter the team name here. Leave blank"
			echo "for none."
			echo ""
			echo -n "Please enter the Bitbucket team (press [ENTER] if none): "
			read REPOHOSTINGSERVICEORGANIZATION
			local REPOHOSTINGSERVICEORGANIZATION_OK=false
			while [ ${REPOHOSTINGSERVICEORGANIZATION_OK} != true ]
			do
				if [[ ! "${REPOHOSTINGSERVICEORGANIZATION}" =~ ^[a-zA-Z][a-zA-Z0-9\-]*$ ]] && # don't forget to update the parameter check if you change something here!
				   [ "${REPOHOSTINGSERVICEORGANIZATION}" != "" ]
				then
					echo -n "Invalid, try again: "
					read REPOHOSTINGSERVICEORGANIZATION
					continue 1
				else
					local REPOHOSTINGSERVICEORGANIZATION_OK=true
					break 1
				fi
			done
		fi
	fi

	return 0
}


####
# Let the user decide if the remote repository shall be private or public
#
# This function is setting the global REPOHOSTINGSERVICEREPOACCESS var. It is a
# helper of the repowizard_start function.
#
# @return integer 0 if everything was fine, 1 if there was an error.
# @author Andreas Haerter <ah@bitkollektiv.org>
function repowizard_step4_repoaccess() {
	REPOHOSTINGSERVICEREPOACCESS="" # init the global var this wizard is for
	if [ "${OPTION_REPOHOSTINGSERVICEREPOACCESS}" != "" ]
	then
		echo ""
		echo "Who has access to the new remote repository was specified by parameter."
		echo "Using '${OPTION_REPOHOSTINGSERVICEREPOACCESS}'."
		REPOHOSTINGSERVICEREPOACCESS=${OPTION_REPOHOSTINGSERVICEREPOACCESS}
	else
		echo ""
		if [ "${REPOHOSTINGSERVICE}" == "github" ]
		then
			echo -e "\033[1mNOTE:\033[0m You need a fitting GitHub plan to be able to create private"
			echo    "      repositories."
			echo    ""
		fi
		echo "You have to decide who has access to the new remote repository. Please"
		echo "choose the rule you want to use by typing the corresponding number:"
		echo ""
		echo "- 0: public (anyone has read access, e.g. for Open Source)"
		echo "- 1: private (only I and the people I specify have access)"
		echo ""
		echo -n "Number identifying the access rule to use? "
		read CHOICE
		local CHOICE_OK=false
		while [ ${CHOICE_OK} != true ]
		do
			if [ "${CHOICE}" == "" ] ||
			   [[ ! "${CHOICE}" =~ ^[0-1]*$ ]]
			then
				echo -n "Invalid, try again: "
				read CHOICE
				continue 1
			else
				local CHOICE_OK=true
				break 1
			fi
		done
		# clean up
		unset CHOICE_OK
		if [ "${CHOICE}" == "0" ]
		then
			REPOHOSTINGSERVICEREPOACCESS="public" # var we need to process the repo creation
		else
			REPOHOSTINGSERVICEREPOACCESS="private" # var we need to process the repo creation
		fi
		unset CHOICE
	fi
	return 0
}


####
# Creates a repository/project on GitHub.
#
# @return integer 0 if everything was fine, 1 if there was an error.
# @author Andreas Haerter <ah@bitkollektiv.org>
# @link http://developer.github.com/v3/repos/
# @link http://developer.github.com/v3/#authentication
# @link http://blog.httpwatch.com/2009/02/20/how-secure-are-query-strings-over-https/
function github_createrepo() {
	# init
	local API_TARGETURL="https://api.github.com/user/repos"
	local PARAM_NAME=${REPOHOSTINGSERVICEPROJECTNAME}
	local PARAM_DESCRIPTION="Puppet module ${NEWMODNAME}"
	local PARAM_PRIVATE="true"
	local PARAM_ISSUES="false"
	local PARAM_WIKI="false"
	local PARAM_DOWNLOADS="false"

	# adjust some parameters
	if [ "${REPOHOSTINGSERVICEORGANIZATION}" != "" ]
	then
		local API_TARGETURL="https://api.github.com/orgs/${REPOHOSTINGSERVICEORGANIZATION}/repos"
	fi
	if [ "${REPOHOSTINGSERVICEREPOACCESS}" == "public" ]
	then
		local PARAM_PRIVATE="false"
	fi

	# let's go
	echo ""
	if [ "${REPOHOSTINGSERVICEORGANIZATION}" == "" ]
	then
		echo "Creating GitHub project: ${REPOHOSTINGSERVICEUSERNAME}/${REPOHOSTINGSERVICEPROJECTNAME}"
	else
		echo "Creating GitHub project: ${REPOHOSTINGSERVICEORGANIZATION}/${REPOHOSTINGSERVICEPROJECTNAME}"
	fi
	local RESPONSE=$(curl -# --request POST --user "${REPOHOSTINGSERVICEUSERNAME}:${REPOHOSTINGSERVICEPWD}" --data "{\"name\":\"${PARAM_NAME}\",\"description\":\"${PARAM_DESCRIPTION}\",\"private\":${PARAM_PRIVATE},\"has_issues\":${PARAM_ISSUES},\"has_wiki\":${PARAM_WIKI},\"has_downloads\":${PARAM_DOWNLOADS}}" ${API_TARGETURL})
	if [ $? -eq 7 ] # failed to connect to host.
	then
		echo ""
		echo -e "\033[31mCreating the new project on GitHub failed.\033[0m (failed to connect to host)" 1>&2
		echo ""
		return 1
	elif [ "${RESPONSE}" == "" ] ||
	     [[ "${RESPONSE}" == *"ad credentials"* ]] ||
	     [[ "${RESPONSE}" == *"Error"* ]] ||
	     [[ "${RESPONSE}" == *"error"* ]]
	then
		echo ""
		echo -e "\033[31mCreating the new project on GitHub failed.\033[0m" 1>&2
		if [ "${RESPONSE}" != "" ]
		then
			echo "Original GitHub response:" 1>&2
			echo "" 1>&2
			echo ${RESPONSE} 1>&2
			echo "" 1>&2
		fi
		return 1
	else
		echo -e "\033[32mDone.\033[0m"
	fi
	return 0
}


####
# Creates a repository on Bitbucket.
#
# @return integer 0 if everything was fine, 1 if there was an error.
# @author Andreas Haerter <ah@bitkollektiv.org>
# @link http://confluence.atlassian.com/display/BITBUCKET/Repositories#Repositories-CreatingaNewRepository
function bitbucket_createrepo() {
	# init
	local API_TARGETURL="https://api.bitbucket.org/1.0/repositories/"
	local PARAM_NAME=${REPOHOSTINGSERVICEPROJECTNAME}
	local PARAM_DESCRIPTION="Puppet module ${NEWMODNAME}"
	local PARAM_PRIVATE="true"
	local PARAM_ISSUES="false"
	local PARAM_WIKI="false"
	local PARAM_SCM="git"
	local PARAM_OWNER="${REPOHOSTINGSERVICEORGANIZATION}"

	# adjust some parameters
	if [ "${REPOHOSTINGSERVICEREPOACCESS}" == "public" ]
	then
		local PARAM_PRIVATE="false"
	fi

	# let's go
	echo ""
	if [ "${REPOHOSTINGSERVICEORGANIZATION}" == "" ]
	then
		echo "Creating Bitbucket project: ${REPOHOSTINGSERVICEUSERNAME}/${REPOHOSTINGSERVICEPROJECTNAME}"
	else
		echo "Creating Bitbucket project: ${REPOHOSTINGSERVICEORGANIZATION}/${REPOHOSTINGSERVICEPROJECTNAME}"
	fi
	if [ "${REPOHOSTINGSERVICEORGANIZATION}" == "" ]
	then
		local RESPONSE=$(curl -# --request POST --user "${REPOHOSTINGSERVICEUSERNAME}:${REPOHOSTINGSERVICEPWD}" --data "name=${PARAM_NAME}" --data "is_private=${PARAM_PRIVATE}" --data "scm=${PARAM_SCM}" --data "description=${PARAM_DESCRIPTION}" --data "has_issues=${PARAM_ISSUES}" --data "has_wiki=${PARAM_WIKI}" ${API_TARGETURL})
	else
		local RESPONSE=$(curl -# --request POST --user "${REPOHOSTINGSERVICEUSERNAME}:${REPOHOSTINGSERVICEPWD}" --data "name=${PARAM_NAME}" --data "is_private=${PARAM_PRIVATE}" --data "scm=${PARAM_SCM}" --data "description=${PARAM_DESCRIPTION}" --data "has_issues=${PARAM_ISSUES}" --data "has_wiki=${PARAM_WIKI}" --data "owner=${PARAM_OWNER}" ${API_TARGETURL})
	fi

	if [ $? -eq 7 ] # failed to connect to host.
	then
		echo ""
		echo -e "\033[31mCreating the new project on Bitbucket failed.\033[0m (failed to connect to host)" 1>&2
		echo ""
		return 1
	elif [ "${RESPONSE}" == "" ] ||
	     [[ "${RESPONSE}" == *"ad Request"* ]] ||
	     [[ "${RESPONSE}" == *"rrorlist"* ]]
	then
		echo ""
		echo -e "\033[31mCreating the new project on Bitbucket failed.\033[0m (maybe bad credentials?)" 1>&2
		if [ "${RESPONSE}" != "" ]
		then
			echo "Original Bitbucket response:" 1>&2
			echo "" 1>&2
			echo ${RESPONSE} 1>&2
			echo "" 1>&2
		fi
		return 1
	else
		echo -e "\033[32mDone.\033[0m"
	fi
	return 0
}



################################################################################
# Environment Variables
################################################################################
set +u # allow usage of uninitialized variables

ENV_AUTHOREMAIL="" #init value of PUPPET_BOILERPLATE_AUTHORFULLNAME
ENV_AUTHORFULLNAME="" #init value of PUPPET_BOILERPLATE_AUTHOREMAIL

# name of the author
ENV_AUTHORFULLNAME="${PUPPET_BOILERPLATE_AUTHORFULLNAME}"

# email address of the author
ENV_AUTHOREMAIL="${PUPPET_BOILERPLATE_AUTHOREMAIL}"
if [ "${ENV_AUTHOREMAIL}" != "" ] &&
   [[ "${ENV_AUTHOREMAIL}" != *"@"* ]] # don't forget to update the interactive and parameter variable check if you change something here!
then
	ENV_AUTHOREMAIL=""
	echo "PUPPET_BOILERPLATE_AUTHOREMAIL: invalid value, ignoring it." 1>&2
fi



################################################################################
# Command line arguments
################################################################################
set +u # allow usage of uninitialized variables

OPTION_AUTHORFULLNAME=""                   # init value of -a
OPTION_BOILERPLATE=""                      # init value of -b
OPTION_AUTHOREMAIL=""                      # init value of -e
OPTION_NEWMODNAME=""                       # init value of -n
OPTION_TARGETDIR=""                        # init value of -t
OPTION_REPOHOSTINGSERVICE=""               # init value of -s
OPTION_REPOHOSTINGSERVICEUSERNAME=""       # init value of -u
OPTION_REPOHOSTINGSERVICEPWD=""            # init value of -p
OPTION_REPOHOSTINGSERVICEORGANIZATION=""   # init value of -o
OPTION_REPOHOSTINGSERVICEPROJECTNAME=""    # init value of -q
OPTION_REPOHOSTINGSERVICEREPOACCESS=""     # init value of -r

# parse options
# always helpful: http://rsalveti.wordpress.com/2007/04/03/bash-parsing-arguments-with-getopts/
OPTIND=1
OPTION="" #init loop value
while getopts ":a:b:e:n:t:s:u:p:o:q:r:h?" OPTION
do
	case "${OPTION}" in
		# name of the author
		"a")
			OPTION_AUTHORFULLNAME=${OPTARG}
			;;

		# boilerplate to use
		"b")
			OPTION_BOILERPLATE=${OPTARG} # validation will be done by the listing code
			;;

		# email address of the author
		"e")
			OPTION_AUTHOREMAIL=${OPTARG}
			if [[ "${OPTION_AUTHOREMAIL}" != *"@"* ]] # don't forget to update the interactive and environment variable check if you change something here!
			then
				OPTION_AUTHOREMAIL=""
				echo "-e: invalid value, ignoring it." 1>&2
			fi
			;;

		# name for the new module
		"n")
			OPTION_NEWMODNAME=${OPTARG}
			if [[ ! "${OPTION_NEWMODNAME}" =~ ^[a-z][a-z0-9_]*$ ]] # don't forget to update the interactive check if you change something here!
			then
				OPTION_NEWMODNAME=""
				echo "-n: invalid value, ignoring it." 1>&2
			fi
			;;

		# targetdir, where to put the new module
		"t")
			OPTION_TARGETDIR=${OPTARG}
			if [ "${OPTION_TARGETDIR}" != "/" ]
			then
				OPTION_TARGETDIR="${OPTION_TARGETDIR%/}" # strip trailing slash
			fi
			# don't forget to update the interactive check if you change something here!
			if [ ! -d "${OPTION_TARGETDIR}" ]
			then
				OPTION_TARGETDIR=""
				echo "-t: invalid value, ignoring it." 1>&2
			fi
			if [ -d "${OPTION_TARGETDIR}/${OPTION_NEWMODNAME}" ] &&
			   [ "${OPTION_NEWMODNAME}" != "" ]
			then
				OPTION_TARGETDIR=""
				echo "-t: invalid value, ignoring it." 1>&2
			fi
			;;

		# DVCS repository hosting service
		"s")
			OPTION_REPOHOSTINGSERVICE=${OPTARG}
			if [ "${OPTION_REPOHOSTINGSERVICE}" != "bitbucket" ] &&
			   [ "${OPTION_REPOHOSTINGSERVICE}" != "github" ]
			then
				OPTION_REPOHOSTINGSERVICE=""
				echo "-s: invalid value, ignoring it." 1>&2
			fi
			;;

		# DVCS repository hosting service: username
		"u")
			OPTION_REPOHOSTINGSERVICEUSERNAME=${OPTARG}
			;;

		# DVCS repository hosting service: password belonging to the username
		"p")
			OPTION_REPOHOSTINGSERVICEPWD=${OPTARG}
			;;

		# DVCS repository hosting service: organization
		"o")
			OPTION_REPOHOSTINGSERVICEORGANIZATION=${OPTARG}
			if [[ ! "${OPTION_REPOHOSTINGSERVICEORGANIZATION}" =~ ^[a-zA-Z][a-zA-Z0-9\-]*$ ]] # don't forget to update the interactive check if you change something here!
			then
				OPTION_REPOHOSTINGSERVICEORGANIZATION=""
				echo "-o: invalid value, ignoring it." 1>&2
			fi
			;;

		# DVCS repository hosting service: name for the new project
		"q")
			OPTION_REPOHOSTINGSERVICEPROJECTNAME=${OPTARG}
			if [[ ! "${OPTION_REPOHOSTINGSERVICEPROJECTNAME}" =~ ^[a-zA-Z0-9_\-]*$ ]] # don't forget to update the interactive check if you change something here!
			then
				OPTION_REPOHOSTINGSERVICEPROJECTNAME=""
				echo "-q: invalid value, ignoring it." 1>&2
			fi
			;;

		# DVCS repository hosting service: access setting for the new project
		"r")
			OPTION_REPOHOSTINGSERVICEREPOACCESS=${OPTARG}
			if [ "${OPTION_REPOHOSTINGSERVICEREPOACCESS}" != "public" ] &&
			   [ "${OPTION_REPOHOSTINGSERVICEREPOACCESS}" != "private" ]
			then
				OPTION_REPOHOSTINGSERVICEREPOACCESS=""
				echo "-r: invalid value, ignoring it." 1>&2
			fi
			;;

		# show help
		"h"|"?")
			FILENAME=$(basename "${0}")
			echo    ""
			echo -e "\033[1mSYNOPSIS\033[0m"
			echo    "  ${FILENAME} [-a author] [-b boilerplate] [-n modname] [-t /targetdir]"
			echo    "  [-e author@example.com] [-h|-?]"
			echo    ""
			echo    ""
			echo -e "\033[1mOPTIONS\033[0m"
			echo    ""
			echo -e "  \033[1m-a\033[0m"
			echo    "    Author name, used for the source code author information of the new module."
			echo    ""
			echo -e "  \033[1m-b\033[0m"
			echo    "    Boilerplate to use (full name, e.g. \"application\")."
			echo    ""
			echo -e "  \033[1m-e\033[0m"
			echo    "    Email address of the author, used for the source code author information"
			echo    "    of the new module."
			echo    ""
			echo -e "  \033[1m-n\033[0m"
			echo    "    Name of the new module. Please note that module names are restricted to"
			echo    "    lowercase alphanumeric characters and underscores, and should begin with"
			echo    "    a lowercase letter."
			echo    ""
			echo -e "  \033[1m-t\033[0m"
			echo    "    Target directory in which the module shall be copied."
			echo    ""
			echo -e "  \033[1m-s\033[0m"
			echo    "     DVCS repository wizard: Repository hosting service to use. Available:"
			echo    "     bitbucket, github"
			echo    ""
			echo -e "  \033[1m-u\033[0m"
			echo    "    DVCS repository wizard: your username on the repository hosting service"
			echo    "    of choice."
			echo    ""
			echo -e "  \033[1m-p\033[0m"
			echo    "     DVCS repository wizard: your password belonging to the username on"
			echo    "     the repository hosting service of choice."
			echo    "     ATTENTION: Do not use this on multi-user machines! Your password may be"
			echo    "                listed in the terminal history, current processes listing, ..."
			echo    ""
			echo -e "  \033[1m-o\033[0m"
			echo    "     DVCS repository wizard: Most services provide some kind of multi-user"
			echo    "     feature. You can use this option if you want to create the repository"
			echo    "     in such a multi-user-organization/team account instead of putting the"
			echo    "     repository in your personal account. Just submit the name of it by using"
			echo    "     this option. Supported right now:"
			echo    "     - GitHub organizations"
			echo    "     - Bitbucket teams"
			echo    ""
			echo -e "  \033[1m-q\033[0m"
			echo    "    DVCS repository wizard: Project name to user for the new repository on"
			echo    "    the repository hosting service of choice."
			echo    ""
			echo -e "  \033[1m-r\033[0m"
			echo    "     DVCS repository wizard: access setting for the new project on the"
			echo    "     repository hosting service. Available: public, private"
			echo    ""
			echo -e "  \033[1m-h|?\033[0m"
			echo    "    Print this help."
			echo    ""
			echo    ""
			echo -e "\033[1mUSAGE\033[0m"
			echo    ""
			echo    "  Just call this program and follow the instructions. Every value this program"
			echo    "  is asking for can be defined as parameter (see listing above). So it is able"
			echo    "  to work without user interaction if all needed values are specified. Invalid"
			echo    "  values will be ignored and the user will be asked for a valid value instead."
			echo    ""
			echo    ""
			echo -e "\033[1mENVIRONMENT VARIABLES\033[0m"
			echo    ""
			echo    "  This program uses the following environment variables:"
			echo    ""
			echo -e "       \033[4mPUPPET_BOILERPLATE_AUTHORFULLNAME\033[0m"
			echo    "           Allows the specification of a default value for the author's name."
			echo -e "           This var's value will be ignored if \033[1m-a\033[0m is set."
			echo    ""
			echo -e "       \033[4mPUPPET_BOILERPLATE_AUTHOREMAIL\033[0m"
			echo    "           Allows the specification of a default value for the author's email"
			echo -e "           address. This var's value will be ignored if \033[1m-e\033[0m is set."
			echo    ""
			unset FILENAME
			exit 0
			;;

		# unknown/not supported -> kill script and inform user
		*)
			echo "unknown option '${OPTARG}'. Use '-h' or '-?' to get usage instructions." 1>&2
			exit 1
			;;
	esac
done
unset OPTIND
unset OPTION



################################################################################
# Process
################################################################################
set -u # prevent usage of uninitialized variables

#### welcome user
clear
echo "###############################################################################"
echo "# Puppet module creator"
echo "###############################################################################"


#### check config
if [ ! -d "${DIR_BOILERPLATES}" ]
then
	echo "" 1>&2
	echo "Could not access the boilerplate directory:" 1>&2
	echo "${DIR_BOILERPLATES}" 1>&2
	exit 1
fi


#### start data wizard
wizard_start


#### copy
echo ""
echo -e "\033[1mCopying boilerplate sources...\033[0m"
mkdir -p "${TARGETDIR}" > /dev/null 2>&1
if [ $? -ne 0 ]
then
	echo "Could not create '${TARGETDIR}'." 1>&2
	exit 1
fi
echo "'${SOURCEDIR}' -> '${TARGETDIR}'"
rsync --verbose --recursive --whole-file --exclude="DESCRIPTION" --exclude=".git" --exclude=".gitignore" --exclude=".gitattributes" --exclude=".hg" "${SOURCEDIR}/." "${TARGETDIR}/."
if [ $? -ne 0 ]
then
	echo "Copying to '${TARGETDIR}' failed." 1>&2
	exit 1
else
	echo -e "\033[32mDone.\033[0m"
fi


#### rename directories
echo ""
echo -e "\033[1mRenaming directories...\033[0m"
TOUCHED=false
IFS_SAVE=${IFS} # copy current IFS (Internal Field Separator)
IFS=$'\n'
for RESOURCE in $(find "${TARGETDIR}" -type d -not -name "\.git" -not -name "\.hg" | grep "${STR_PLACEHOLDER_BOILERPLATE}" | sort)
do
	# get some data
	RESOURCE_DIR=$(dirname ${RESOURCE})
	RESOURCE_OLDNAME=$(basename ${RESOURCE})
	RESOURCE_NEWNAME=${RESOURCE_OLDNAME/${STR_PLACEHOLDER_BOILERPLATE}/${NEWMODNAME}}

	# jump to next one if only the path (but not the dir/file itself) matched
	if [ "${RESOURCE_OLDNAME}" == "${RESOURCE_NEWNAME}" ]
	then
		continue 1
	fi

	# rename
	mv -i -v "${RESOURCE_DIR}/${RESOURCE_OLDNAME}" "${RESOURCE_DIR}/${RESOURCE_NEWNAME}"
	if [ $? -ne 0 ]
	then
		echo "Renaming '${RESOURCE}' failed." 1>&2
		exit 1
	fi
	TOUCHED=true

	# clean up
	unset RESOURCE_DIR
	unset RESOURCE_OLDNAME
	unset RESOURCE_NEWNAME
done
if [ ${TOUCHED} == false ]
then
	echo "Nothing to rename, no dirname contains '${STR_PLACEHOLDER_BOILERPLATE}'".
fi
echo -e "\033[32mDone.\033[0m"
# clean up
IFS=${IFS_SAVE} # restore IFS (Internal Field Separator)
unset IFS_SAVE
unset RESOURCE
unset TOUCHED


#### rename files
echo ""
echo -e "\033[1mRenaming files...\033[0m"
TOUCHED=false
IFS_SAVE=${IFS} # copy current IFS (Internal Field Separator)
IFS=$'\n'
for RESOURCE in $(find "${TARGETDIR}" -type f -not -wholename "*\/\.git\/*" -not -wholename "*\/\.hg\/*" | grep "${STR_PLACEHOLDER_BOILERPLATE}" | sort)
do
	# get some data
	RESOURCE_DIR=$(dirname ${RESOURCE})
	RESOURCE_OLDNAME=$(basename ${RESOURCE})
	RESOURCE_NEWNAME=${RESOURCE_OLDNAME/${STR_PLACEHOLDER_BOILERPLATE}/${NEWMODNAME}}

	# jump to next one if only the path (but not the dir/file itself) matched
	if [ "${RESOURCE_OLDNAME}" == "${RESOURCE_NEWNAME}" ]
	then
		continue 1
	fi

	# rename
	mv -i -v "${RESOURCE_DIR}/${RESOURCE_OLDNAME}" "${RESOURCE_DIR}/${RESOURCE_NEWNAME}"
	if [ $? -ne 0 ]
	then
		echo "Renaming '${RESOURCE}' failed." 1>&2
		exit 1
	fi
	TOUCHED=true

	# clean up
	unset RESOURCE_DIR
	unset RESOURCE_OLDNAME
	unset RESOURCE_NEWNAME
done
if [ ${TOUCHED} == false ]
then
	echo "Nothing to rename, no filename contains '${STR_PLACEHOLDER_BOILERPLATE}'".
fi
echo -e "\033[32mDone.\033[0m"
# clean up
IFS=${IFS_SAVE} # restore IFS (Internal Field Separator)
unset IFS_SAVE
unset RESOURCE
unset TOUCHED


#### replacing file contents
# modulename
echo ""
str_rreplace "${STR_PLACEHOLDER_BOILERPLATE}" "${NEWMODNAME}" "${TARGETDIR}" true
# author name
echo ""
str_rreplace "${STR_PLACEHOLDER_AUTHORFULLNAME}" "${AUTHORFULLNAME}" "${TARGETDIR}" true
# author email address
echo ""
str_rreplace "${STR_PLACEHOLDER_AUTHOREMAIL}" "${AUTHOREMAIL}" "${TARGETDIR}" true
# year placeholder
echo ""
str_rreplace "${STR_PLACEHOLDER_CURRENTYEAR}" "$(date +'%Y')" "${TARGETDIR}" true


#### user information
echo ""
echo -e "\033[32mThe new module was created successfully.\033[0m"
echo ""
echo ""
echo -e "Start to edit the following files (-> positions marked with '\033[1m${STR_PLACEHOLDER_FIXME}\033[0m')"
echo "for customization:"
IFS_SAVE=${IFS} # copy current IFS (Internal Field Separator)
IFS=$'\n'
for RESOURCE in $(grep -R "${STR_PLACEHOLDER_FIXME}" "${TARGETDIR}" | cut -d ":" -f 1 -s | sort | uniq)
do
	echo "- ${RESOURCE}"
done
IFS=${IFS_SAVE} # restore IFS (Internal Field Separator)
# clean up
IFS=${IFS_SAVE} # restore IFS (Internal Field Separator)
unset IFS_SAVE
unset RESOURCE
echo ""
echo -e "\033[1mBasic work is done, you can start to edit and use the new module now. :-)\033[0m"



##### DVCS repository
echo ""
echo "This program is able to create a new project for your Puppet module on some"
echo "DVCS hosting services. Currently supported:"
echo "  - Git repository on GitHub (including GitHub organizations)"
echo "  - Git repository on Bitbucket (including Bitbucket teams)"
echo ""
echo -n "Start repository hosting service wizard? [y|n]: "
read INPUT
if [ ! "${INPUT}" == "y" ] &&
   [ ! "${INPUT}" == "Y" ] &&
   [ ! "${INPUT}" == "j" ] &&
   [ ! "${INPUT}" == "J" ]
then
	echo ""
	echo "Repository hosting wizard canceled by user. Have fun with your new Puppet"
	echo "module."
	echo ""
	exit 0
fi

hash curl > /dev/null 2>&1
if [ $? -ne 0 ]
then
	echo "curl is missing. Please install it for the next time..." 1>&2
	echo "However: have fun with your new Puppet module." 1>&2
	exit 1
fi
hash git > /dev/null 2>&1
if [ $? -ne 0 ]
then
	echo "git is missing. Please install it for the next time..." 1>&2
	echo "However: have fun with your new Puppet module." 1>&2
	exit 1
fi


#### start repository data wizard
repowizard_start


#### create remote project on repository hosting service
REMOTECREATE_SUCCESS=false #init
while [ ${REMOTECREATE_SUCCESS} == false ]
do
	if [ "${REPOHOSTINGSERVICE}" == "github" ]
	then
		github_createrepo
		if [ $? -eq 0 ]
		then
			REMOTECREATE_SUCCESS=true
		fi
	elif [ "${REPOHOSTINGSERVICE}" == "bitbucket" ]
	then
		bitbucket_createrepo
		if [ $? -eq 0 ]
		then
			REMOTECREATE_SUCCESS=true
		fi
	else
		echo "'${REPOHOSTINGSERVICE}' is an unknown service." 1>&2
		exit 1
	fi

	if [ ${REMOTECREATE_SUCCESS} == false ]
	then
		RETRY="n" #init
		echo -n "Retry? [y|n]: "
		read RETRY
		if [ "${RETRY}" == "y" ] ||
		   [ "${RETRY}" == "Y" ] ||
		   [ "${RETRY}" == "j" ] ||
		   [ "${RETRY}" == "J" ]
		then
			continue 1
		fi
		unset RETRY

		RESTARTWIZARD="n" #init
		echo -n "Restart DVCS wizard? (e.g. correct wrong data, retry afterwards) [y|n]: "
		read RESTARTWIZARD
		if [ "${RESTARTWIZARD}" == "y" ] ||
		   [ "${RESTARTWIZARD}" == "Y" ] ||
		   [ "${RESTARTWIZARD}" == "j" ] ||
		   [ "${RESTARTWIZARD}" == "J" ]
		then
			repowizard_start
			continue 1
		else
			echo ""
			echo "Repository creation canceled by user. However, have fun with your new"
			echo "Puppet module (nothing was modified by the DVCS wizard there, no need"
			echo "to restart the whole module creation)."
			echo ""
			exit 0
		fi
		unset RESTARTWIZARD
	fi
done


#### create local repository
echo ""
echo "Creating local git repository in '${TARGETDIR}'"
git init "${TARGETDIR}" > /dev/null 2>&1 #note: running git init in an existing repository is safe.
if [ $? -ne 0 ]
then
	echo "'git init' failed for '${TARGETDIR}'!" 1>&2
	echo "However, your new Puppet module should be OK. Just create the repository" 1>&2
	echo "by hand. Or delete everything and re-start the module creation." 1>&2
	echo ""
	exit 1
fi
echo -e "\033[32mDone.\033[0m"


#### add git remote
echo ""
if [ "${REPOHOSTINGSERVICE}" == "github" ]
then
	echo "Adding GitHub repository as git remote origin..."
	if [ "${REPOHOSTINGSERVICEORGANIZATION}" == "" ]
	then
		git --git-dir="${TARGETDIR}/.git" --work-tree="${TARGETDIR}" remote add origin "git@github.com:${REPOHOSTINGSERVICEUSERNAME}/${REPOHOSTINGSERVICEPROJECTNAME}.git" > /dev/null 2>&1
	else
		git --git-dir="${TARGETDIR}/.git" --work-tree="${TARGETDIR}" remote add origin "git@github.com:${REPOHOSTINGSERVICEORGANIZATION}/${REPOHOSTINGSERVICEPROJECTNAME}.git" > /dev/null 2>&1
	fi
	if [ $? -ne 0 ]
	then
		echo "'git remote add origin' failed for '${TARGETDIR}'!" 1>&2
		echo "However, your new Puppet module should be OK. Just configure git remote" 1>&2
		echo "by hand. Or delete everything and re-start the module creation." 1>&2
		echo ""
		exit 1
	fi
	echo "You may want to use 'git push -u origin master' after your first commit."
	echo -e "\033[32mDone.\033[0m"
elif [ "${REPOHOSTINGSERVICE}" == "bitbucket" ]
then
	echo "Adding Bitbucket repository as git remote origin..."
	if [ "${REPOHOSTINGSERVICEORGANIZATION}" == "" ]
	then
		git --git-dir="${TARGETDIR}/.git" --work-tree="${TARGETDIR}" remote add origin "git@bitbucket.org:${REPOHOSTINGSERVICEUSERNAME}/${REPOHOSTINGSERVICEPROJECTNAME}.git" > /dev/null 2>&1
	else
		git --git-dir="${TARGETDIR}/.git" --work-tree="${TARGETDIR}" remote add origin "git@bitbucket.org:${REPOHOSTINGSERVICEORGANIZATION}/${REPOHOSTINGSERVICEPROJECTNAME}.git" > /dev/null 2>&1
	fi
	if [ $? -ne 0 ]
	then
		echo "'git remote add origin' failed for '${TARGETDIR}'!" 1>&2
		echo "However, your new Puppet module should be OK. Just configure git remote" 1>&2
		echo "by hand. Or delete everything and re-start the module creation." 1>&2
		echo ""
		exit 1
	fi
	echo "You may want to use 'git push -u origin master' after your first commit."
	echo -e "\033[32mDone.\033[0m"
else
	echo "'${REPOHOSTINGSERVICE}' is an unknown service." 1>&2
	exit 1
fi


echo ""
echo -e "\033[1mThe ${REPOHOSTINGSERVICE} project and the local repository were created successfully.\033[0m"
echo ""
exit 0

