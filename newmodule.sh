#!/bin/sh

################################################################################
# Puppet module creator
#
# Script to create a useful skeleton to start developing a new Puppet module
# based on a boilerplate you choose.
#
# @author Andreas Haerter <ah@syn-systems.com>
# @license Apache License 2.0 (http://www.apache.org/licenses/LICENSE-2.0)
# @link http://syn-systems.com/
################################################################################



################################################################################
# Configuration
################################################################################

# directory where the Puppet module boilerplates are located, without trailing
# slash!
DIR_BOILERPLATES="$(dirname "${0}")"

# some placeholder strings and/or names used within the boilerplate source codes
STR_PLACEHOLDER_BOILERPLATE='boilerplate'
STR_PLACEHOLDER_AUTHORFULLNAME='John Doe'
STR_PLACEHOLDER_AUTHOREMAIL='john.doe@example.com'
STR_PLACEHOLDER_CURRENTYEAR='YYYY'
STR_PLACEHOLDER_FIXME='FIXME/TODO'



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
# @param integer (optional) Verbose flag. Controls if the function should
#        operate silently (=0, default) or not (=1).
# @return integer 0 if executed successfully, 1 otherwise.
str_rreplace() {
	local dir ifs_save lang_save langtmp_ok os replace search touched verbose

	# param: search
	search="${1}"
	if [ -z "${search}" ]
	then
		printf 'Parameter is invalid: search.\n' 1>&2
		return 1
	fi

	# param: replace
	replace="${2}"

	# param: directory
	dir="${3}"
	if [ "${dir}" != '/' ]
	then
		dir="$(printf '%s' "${dir}" | sed 's,/$,,')" # strip trailing slash
	fi
	if ! [ -d "${dir}" ]
	then
		printf 'Could not access directory: "%s"\n' "${dir}" 1>&2
		printf 'Please place this script in the same directory as the boilerplates.\n' 1>&2
		return 1
	fi

	# param: verbose flag
	if [ -z "${4:-}" ] # ${foo:-} works with set -u
	then
		verbose='0'
	else
		verbose="${4}"
	fi
	if [ "${verbose}" -gt 0 ]
	then
		verbose='1'
	else
		verbose='0'
	fi

	# Change current LANG setting for following operations if needed. This
	# prevents issues regarding some commands (e.g. 'sed', 'grep', ...) and the
	# UTF-8 encoded files we are going to work with. Q.v.: <http://j.mp/GgQMV>.
	lang_save="${LANG}" # copy current locale LANG value.
	if ! printf '%s' "${LANG}" | grep -E -q -i -e '*utf-?8$' # current locale is UTF-8 aware?
	then
		# It is not. Search for an alternative...
		langtmp_ok='0'
		for RESOURCE in $(locale -a | grep -E -i -e '*\.utf-?8$' | grep -E -i -e '^(en|de|es|fr)_*' | sort)
		do
			# use it and break loop if a "favorite" (=tested) locale is present
			if printf '%s' "${RESOURCE}" | grep -E -q -i -e '^de_(AT|CH|DE)' ||
			   printf '%s' "${RESOURCE}" | grep -E -q -i -e '^en_(AU|CA|GB|IE|NZ|US)' ||
			   printf '%s' "${RESOURCE}" | grep -E -q -i -e '^es_(ES|MX|US|VE)' ||
			   printf '%s' "${RESOURCE}" | grep -E -q -i -e '^fr_(BE|CA|CH|FR|LU)'
			then
				LANG="${RESOURCE}"
				langtmp_ok='1'
				break
			fi
		done
		unset RESOURCE
		# check if we found something useful...
		if [ "${langtmp_ok}" -ne 1 ]
		then
			LANG="${lang_save}" # restore LANG
			printf 'Current locale is not UTF-8 aware: "%s"\n' "${LANG}" 1>&2
			return 1
		fi
		unset langtmp_ok
	fi

	# inform user
	if [ "${verbose}" -eq 1 ]
	then
		printf '\033[1mReplacing "%s" with "%s"\033[0m\n' "${search}" "${replace}"
	fi

	# let's work
	touched='0'
	ifs_save="${IFS}" # copy current IFS (Internal Field Separator)
	IFS="$(printf '\n+')"
	for RESOURCE in $(grep -R "${search}" "${dir}" | cut -d ":" -f 1 -s | sort | uniq)
	do
		os="$(bash -c 'printf '\''%s'\'' "${OSTYPE}"')" # FIXME better "GNU vs. BSD sed" detection here. Maybe "uname -o"?
		if printf '%s' "${os}" | grep -F -q -i -e 'darwin' || # Mac OS is using BSD sed
		   printf '%s' "${os}" | grep -F -q -i -e 'freebsd'
		then
			sed -i '' -e "s/${search}/${replace}/g" "${RESOURCE}" # BSD style
		else
			sed -i -e "s/${search}/${replace}/g" "${RESOURCE}" # GNU style
		fi
		if [ $? -ne 0 ]
		then
			printf 'Replacing "%s" with "%s" in "%s" failed.\n' "${search}" "${replace}" "${RESOURCE}" 1>&2
			LANG="${lang_save}" # restore LANG
			return 1
		elif [ "${verbose}" -eq 1 ]
		then
			printf 'Changed: "%s"\n' "${RESOURCE}"
		fi
		touched='1'
	done
	IFS="${ifs_save}" # restore IFS (Internal Field Separator)

	if [ "${verbose}" -eq 1 ] &&
	   [ "${touched}" -eq 0 ]
	then
		printf 'Nothing to replace, no file contains "%s".\n' "${search}"
	fi

	printf '\033[32mDone.\033[0m\n'
	LANG="${lang_save}" # restore LANG
	return 0
}


###
# Interactive data collection wizard
#
# @return void
wizard_start() {
	local data_ok exitprog

	wizard_step1_boilerplatetype
	wizard_step2_newmodname
	wizard_step3_targetdir
	wizard_step4_authorfullname
	wizard_step5_authoremail
	# show overview about the collected data (unless everything was set by parameters)
	if [ -z "${OPTION_AUTHORFULLNAME}" ]
	   [ -z "${OPTION_BOILERPLATE}" ]
	   [ -z "${OPTION_AUTHOREMAIL}" ]
	   [ -z "${OPTION_NEWMODNAME}" ]
	   [ -z "${OPTION_TARGETDIR}" ]
	then
		data_ok='n'
		clear
		printf '###############################################################################\n'
		printf '# Puppet module creator: data overview\n'
		printf '###############################################################################\n'
		printf '\033[1mBoilerplate source:\033[0m\n%s\n\n' "${SOURCEDIR}"
		printf '\033[1mNew module will be created in:\033[0m\n%s\n\n' "${TARGETDIR}"
		printf '\033[1mAuthor/creator of the new module:\033[0m\n%s <%s>\n\n' "${AUTHORFULLNAME}" "${AUTHOREMAIL}"
		printf 'Is this correct? [y|n]: '
		read data_ok
		while [ "${data_ok}" != 'y' ] &&
		      [ "${data_ok}" != 'Y' ] &&
		      [ "${data_ok}" != 'j' ] &&
		      [ "${data_ok}" != 'J' ]
		do
			exitprog='n'
			printf 'Exit program? [y|n]: '
			read exitprog
			if [ "${exitprog}" = 'y' ] ||
			   [ "${exitprog}" = 'Y' ] ||
			   [ "${exitprog}" = 'j' ] ||
			   [ "${exitprog}" = 'J' ]
			then
				printf 'Operation canceled by user\n\n'
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
			printf '###############################################################################\n'
			printf '# Puppet module creator: data overview\n'
			printf '###############################################################################\n'
			printf '\033[1mBoilerplate source:\033[0m\n%s\n\n' "${SOURCEDIR}"
			printf '\033[1mNew module will be created in:\033[0m\n%s\n\n' "${TARGETDIR}"
			printf '\033[1mAuthor/creator of the new module:\033[0m\n%s <%s>\n\n' "${AUTHORFULLNAME}" "${AUTHOREMAIL}"
			printf 'Is this correct? [y|n]: '
			read data_ok
		done
		printf '\n'
	fi
	unset data_ok
}


###
# Let the user decide which type of boilerplate we are going to use
#
# This function is setting the global SOURCEDIR var. It is a helper of the
# wizard_start function.
#
# @return integer 0 if executed successfully, 1 otherwise.
wizard_step1_boilerplatetype() {
	local basename choice_ok list choice list_itemcount i ifs_save

	printf '\n'
	printf 'Please choose the type of boilerplate to use for the new module by typing the\n'
	printf 'corresponding number:\n'
	printf '\n'
	SOURCEDIR='' # init the global var this wizard is for

	# show a list the user can choose from
	list=''
	choice='none'
	i='1'
	ifs_save="${IFS}" # copy current IFS (Internal Field Separator)
	IFS="$(printf '\n+')"
	for ITEM in $(find "${DIR_BOILERPLATES}" -maxdepth 1 -type d -not -name '\.git' -not -name '\.hg' | sort)
	do
		# sort-out non-boilerplate directories
		if [ "${ITEM}" = "${DIR_BOILERPLATES}" ] || # containing dir itself
		   [ ! -f "${ITEM}/manifests/init.pp" ]
		then
			continue 1
		fi

		# show the item and its number
		basename="$(basename "${ITEM}")"
		printf '  \033[1m%2u: %s\033[0m\n' "${i}" "${basename}"
		if [ -f "${ITEM}/DESCRIPTION" ]
		then
			for LINE in $(cat "${ITEM}/DESCRIPTION")
			do
				printf '      %s\n' "${LINE}"
			done
			unset LINE
		fi
		printf '\n'

		# pre-select item if specified by parameter
		if [ "${OPTION_BOILERPLATE}" = "${basename}" ]
		then
			choice="${i}"
		fi

		# store item in list (separated by ":")
		list="${list}${ITEM}:"
		i="$((${i}+1))"
	done
	unset ITEM
	unset i
	IFS="${ifs_save}" # restore IFS (Internal Field Separator)
	unset ifs_save
	list="$(printf '%s' "${list}" | sed 's,:$,,')" # strip trailing ":" separator


	# count list items
	list_itemcount="$(printf '%s' "${list}" | sed 's/[^:]//g' | wc -m)" # count number of ":"
	list_itemcount="$((list_itemcount+1))"
	if [ "${list_itemcount}" -eq 0 ]
	then
		printf '\n' 1>&2
		printf 'Could not find any boilerplates in "%s".\n' "${DIR_BOILERPLATES}" 1>&2
		exit 1
	fi


	# choose list item
	printf '\n'
	if [ "${list_itemcount}" -eq 1 ]
	then
		choice="${list_itemcount}"
		SOURCEDIR="$(printf '%s' "${list}" | cut -d ':' -f "${choice}")"
		printf 'There is only one boilerplate, therefore nothing to choose.\n'
		printf 'Using "%s".\n' "$(basename "${SOURCEDIR}")"
	elif [ "${choice}" != 'none' ]
	then
		SOURCEDIR="$(printf '%s' "${list}" | cut -d ':' -f "${choice}")"
		printf 'Boilerplate to use was specified by parameter.\n'
		printf 'Using "%s".\n' "$(basename "${SOURCEDIR}")"
	else
		if [ -n "${OPTION_BOILERPLATE}" ] &&
		   [ "${choice}" = 'none' ]
		then
			OPTION_BOILERPLATE=''
			printf '%s' '-b: ' 1>&2
			printf 'invalid value, ignoring it.' 1>&2
		fi
		printf 'See http://j.mp/X3GnY9 for example modules based on the different boilerplates.\n'
		printf 'Number identifying the boilerplate to use? '
		read choice
		choice_ok='0'
		while [ "${choice_ok}" -ne 1 ]
		do
			if [ -z "${choice}" ] ||
			   ! printf '%s' "${choice}" | grep -E -q -e '^[0-9]*$' ||
			   [ "${choice}" -gt "${list_itemcount}" ] ||
			   [ "${choice}" -lt 1 ]
			then
				printf 'Invalid, try again: '
				read choice
				continue 1
			else
				choice_ok='1'
				break 1
			fi
		done
		unset choice_ok
		SOURCEDIR="$(printf '%s' "${list}" | cut -d ':' -f "${choice}")"
	fi

	unset list
	unset choice
	return 0
}


###
# Let the user set the name of the new module
#
# This function is setting the global NEWMODNAME var. It is a helper of the
# wizard_start function.
#
# @return integer 0 if executed successfully, 1 otherwise.
wizard_step2_newmodname() {
	local newmodname_ok

	NEWMODNAME='' # init the global var this wizard is for
	if [ -n "${OPTION_NEWMODNAME}" ]
	then
		printf '\n'
		printf 'Name of the new module was specified by parameter.\n'
		printf 'Using "%s".\n' "${OPTION_NEWMODNAME}"
		NEWMODNAME="${OPTION_NEWMODNAME}"
	else
		# inform user about the naming rules, cf. http://j.mp/xuM3Rr and http://j.mp/wZ8quk
		printf '\n'
		printf '\n'
		printf 'NOTE: module names are restricted to lowercase alphanumeric characters and\n'
		printf '      underscores, and should begin with a lowercase letter; that is, they\n'
		printf '      have to match the pattern "^[a-z][a-z0-9_]*$"\n'
		printf '\n'
		printf 'Please enter the name for the new module: '
		read NEWMODNAME
		newmodname_ok='0'
		while [ "${newmodname_ok}" -ne 1 ]
		do
			if [ -z "${NEWMODNAME}" ] ||
			   ! printf '%s' "${NEWMODNAME}" | grep -E -q -e '^[a-z][a-z0-9_]*$' # don't forget to update the parameter check if you change something here!
			then
				printf 'Invalid, try again: '
				read NEWMODNAME
				continue 1
			else
				newmodname_ok='1'
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
# @return integer 0 if executed successfully, 1 otherwise.
wizard_step3_targetdir() {
	local targetdir_ok

	TARGETDIR='' # init the global var this wizard is for
	if [ -n "${OPTION_TARGETDIR}" ]
	then
		printf '\n'
		printf 'Target directory in which the module shall be copied was specified by parameter.\n'
		printf 'Using "%s".\n' "${OPTION_TARGETDIR}"
		TARGETDIR="${OPTION_TARGETDIR}"
	else
		printf '\n'
		printf 'Please enter the target directory in which the module shall be copied\n'
		printf 'to (just press [ENTER] for "%s"): ' "${HOME}"
		read TARGETDIR
		if [ "${TARGETDIR}" != '/' ]
		then
			TARGETDIR="$(printf '%s' "${TARGETDIR}" | sed 's,/$,,')" # strip trailing slash
		fi
		targetdir_ok='0'
		while [ "${targetdir_ok}" -ne 1 ]
		do
			if [ -z "${TARGETDIR}" ]
			then
				# use home of current user if user just pressed [ENTER]
				TARGETDIR="${HOME}"
			fi
			# don't forget to update the parameter checks if you change something here!
			if [ ! -d "${TARGETDIR}" ]
			then
				printf 'Could not access target, try again: '
				read TARGETDIR
				if [ "${TARGETDIR}" != '/' ]
				then
					TARGETDIR="$(printf '%s' "${TARGETDIR}" | sed 's,/$,,')" # strip trailing slash
				fi
				continue 1
			elif [ -d "${TARGETDIR}/${NEWMODNAME}" ]
			then
				printf '"%s" is already existing.\n' "${TARGETDIR}/${NEWMODNAME}"
				printf 'Target invalid, try again: '
				read TARGETDIR
				if [ "${TARGETDIR}" != '/' ]
				then
					TARGETDIR="$(printf '%s' "${TARGETDIR}" | sed 's,/$,,')" # strip trailing slash
				fi
				continue 1
			else
				targetdir_ok='1'
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
# @return integer 0 if executed successfully, 1 otherwise.
wizard_step4_authorfullname() {
	local authorfullname_ok

	AUTHORFULLNAME='' # init the global var this wizard is for
	if [ -n "${OPTION_AUTHORFULLNAME}" ]
	then
		printf '\n'
		printf 'Name of the author was specified by parameter.\n'
		printf 'Using "%s".\n' "${OPTION_AUTHORFULLNAME}"
		AUTHORFULLNAME="${OPTION_AUTHORFULLNAME}"
	else
		printf '\n'
		if [ -z "${ENV_AUTHORFULLNAME}" ]
		then
			printf 'Please enter your full name (source code author info): '
		else
			printf 'Please enter your full name (source code author info, just press [ENTER]\n'
			printf 'for "%s"): ' "${ENV_AUTHORFULLNAME}"
		fi
		read AUTHORFULLNAME
		authorfullname_ok='0'
		while [ "${authorfullname_ok}" -ne 1 ]
		do
			if [ -z "${AUTHORFULLNAME}" ] &&
			   [ -z "${ENV_AUTHORFULLNAME}" ]
			then
				printf 'Invalid, try again: '
				read AUTHORFULLNAME
				continue 1
			elif [ -z "${AUTHORFULLNAME}" ] &&
			     [ -z "${ENV_AUTHORFULLNAME}" ]
			then
				# use environment variable if user just pressed [ENTER]
				AUTHORFULLNAME="${ENV_AUTHORFULLNAME}"
			else
				authorfullname_ok='1'
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
# @return integer 0 if executed successfully, 1 otherwise.
wizard_step5_authoremail() {
	local authoremail_ok

	AUTHOREMAIL='' # init the global var this wizard is for
	if [ -n "${OPTION_AUTHOREMAIL}" ]
	then
		printf '\n'
		printf 'Email address of the author was specified by parameter.\n'
		printf 'Using "%s".\n' "${OPTION_AUTHOREMAIL}"
		AUTHOREMAIL="${OPTION_AUTHOREMAIL}"
	else
		printf '\n'
		if [ -z "${ENV_AUTHOREMAIL}" ]
		then
			printf 'Please enter your email address (source code author info): '
		else
			printf 'Please enter your email address (source code author info, just press [ENTER]\n'
			printf 'for "%s"): ' "${ENV_AUTHOREMAIL}"
		fi
		read AUTHOREMAIL
		authoremail_ok='0'
		while [ "${authoremail_ok}" -ne 1 ]
		do
			if ([ -z "${AUTHOREMAIL}" ] &&
			    [ -z "${ENV_AUTHOREMAIL}" ]) ||
			   ([ -n "${AUTHOREMAIL}" ] &&
			    ! printf '%s' "${AUTHOREMAIL}" | grep -F -q -e '@') # don't forget to update the parameter and environment variable check if you change something here!
			then
				printf 'Invalid, try again: '
				read AUTHOREMAIL
				continue 1
			elif [ -z "${AUTHOREMAIL}" ] &&
			     [ -n "${ENV_AUTHOREMAIL}" ]
			then
				# use environment variable if user just pressed [ENTER]
				AUTHOREMAIL="${ENV_AUTHOREMAIL}"
			else
				authoremail_ok='1'
				break 1
			fi
		done
	fi
	return 0
}


###
# Interactive data collection wizard
#
# @return void
repowizard_start() {
	local data_ok exitprog

	repowizard_step1_service
	repowizard_step2_remotename
	repowizard_step3_credentials
	repowizard_step4_repoaccess
	# show overview about the collected data (unless everything was set by parameters)
	if [ -z "${OPTION_REPOHOSTINGSERVICE}" ] ||
	   [ -z "${OPTION_REPOHOSTINGSERVICEPROJECTNAME}" ] ||
	   [ -z "${OPTION_REPOHOSTINGSERVICEUSERNAME}" ] ||
	   [ -z "${OPTION_REPOHOSTINGSERVICEPWD}" ] ||
	   [ -z "${OPTION_REPOHOSTINGSERVICEORGANIZATION}" ] ||
	   [ -z "${OPTION_REPOHOSTINGSERVICEREPOACCESS}" ]
	then
		data_ok='n'
		clear
		printf '###############################################################################\n'
		printf '# Puppet module creator: DVCS repository wizard data overview\n'
		printf '###############################################################################\n'
		printf '\033[1mRepository hosting service:\033[0m\n%s\n\n' "${REPOHOSTINGSERVICE}"
		printf '\033[1mRepository/project name:\033[0m\n%s\n\n' "${REPOHOSTINGSERVICEPROJECTNAME}"
		printf '\033[1mUsername:\033[0m\n%s (password not shown for security reasons)\n\n' "${REPOHOSTINGSERVICEUSERNAME}"
		if [ "${REPOHOSTINGSERVICE}" = 'github' ] ||
		   [ "${REPOHOSTINGSERVICE}" = 'bitbucket' ]
		then
			if [ "${REPOHOSTINGSERVICE}" = 'github' ]
			then
				printf '\033[1mOrganization:\033[0m\n'
			else
				printf '\033[1mTeam:\033[0m\n'
			fi
			if [ -z "${REPOHOSTINGSERVICEORGANIZATION}" ]
			then
				printf '(none)\n'
			else
				printf '%s\n' "${REPOHOSTINGSERVICEORGANIZATION}"
			fi
			printf '\n'
		fi
		printf '\033[1mRepository access:\033[0m\n%s\n\n' "${REPOHOSTINGSERVICEREPOACCESS}"
		printf 'Is this correct? [y|n]: '
		read data_ok
		while [ "${data_ok}" != 'y' ] &&
		      [ "${data_ok}" != 'Y' ] &&
		      [ "${data_ok}" != 'j' ] &&
		      [ "${data_ok}" != 'J' ]
		do
			exitprog='n'
			printf 'Exit program? [y|n]: '
			read exitprog
			if [ "${exitprog}" = 'y' ] ||
			   [ "${exitprog}" = 'Y' ] ||
			   [ "${exitprog}" = 'j' ] ||
			   [ "${exitprog}" = 'J' ]
			then
				printf 'Repository creation canceled by user. However, have fun with your new Puppet\n'
				printf 'module.\n\n'
				exit 0
			fi
			# once more with feeling...
			clear
			repowizard_step1_service
			repowizard_step2_remotename
			repowizard_step3_credentials
			repowizard_step4_repoaccess
			clear
			printf '###############################################################################\n'
			printf '# Puppet module creator: DVCS repository wizard data overview\n'
			printf '###############################################################################\n'
			printf '\033[1mRepository hosting service:\033[0m\n%s\n\n' "${REPOHOSTINGSERVICE}"
			printf '\033[1mRepository/project name:\033[0m\n%s\n\n' "${REPOHOSTINGSERVICEPROJECTNAME}"
			printf '\033[1mUsername:\033[0m\n%s (password not shown for security reasons)\n\n' "${REPOHOSTINGSERVICEUSERNAME}"
			if [ "${REPOHOSTINGSERVICE}" = 'github' ] ||
			   [ "${REPOHOSTINGSERVICE}" = 'bitbucket' ]
			then
				if [ "${REPOHOSTINGSERVICE}" = 'github' ]
				then
					printf '\033[1mOrganization:\033[0m\n'
				else
					printf '\033[1mTeam:\033[0m\n'
				fi
				if [ -z "${REPOHOSTINGSERVICEORGANIZATION}" ]
				then
					printf '(none)\n'
				else
					printf '%s\n' "${REPOHOSTINGSERVICEORGANIZATION}"
				fi
				printf '\n'
			fi
			printf '\033[1mRepository access:\033[0m\n%s\n\n' "${REPOHOSTINGSERVICEREPOACCESS}"
			printf 'Is this correct? [y|n]: '
			read data_ok
		done
		printf '\n'
	fi
	unset data_ok
}


###
# Let the user decide which repository hosting service he want to use
#
# This function is setting the global REPOHOSTINGSERVICE var. It is a helper of
# the repowizard_start function.
#
# @return integer 0 if executed successfully, 1 otherwise.
repowizard_step1_service() {
	local choice_ok list list_raw choice list_itemcount i ifs_save item_lower

	printf '\n'
	printf 'Please choose the service you want to use to host the repository for your\n'
	printf 'new module by typing the corresponding number:\n'
	printf '\n'
	REPOHOSTINGSERVICE='' # init the global var this wizard is for

	# show a list the user can choose from
	list_raw='Bitbucket:GitHub'
	list=''
	choice='none'
	i='1'
	ifs_save="${IFS}" # copy current IFS (Internal Field Separator)
	IFS=':'
	for ITEM in ${list_raw}
	do
		# show the item and its number
		printf '  %s: %s\n' "${i}" "${ITEM}"

		# pre-select item if specified by parameter
		item_lower="$(printf '%s' "${ITEM}" | tr A-Z a-z)"
		if [ -n "${item_lower}" ] &&
		   [ "${item_lower}" = "$(printf '%s' "${OPTION_REPOHOSTINGSERVICE}" | tr A-Z a-z)" ]
		then
			choice="${i}"
		fi

		# store item in list (separated by ":")
		list="${list}${item_lower}:"
		i="$((${i}+1))"
	done
	unset ITEM
	unset i
	IFS="${ifs_save}" # restore IFS (Internal Field Separator)
	unset ifs_save
	unset item_lower
	list="$(printf '%s' "${list}" | sed 's,:$,,')" # strip trailing ":" separator

	# count list items
	list_itemcount="$(printf '%s' "${list}" | sed 's/[^:]//g' | wc -m)" # count number of ":"
	list_itemcount="$((list_itemcount+1))"
	if [ "${list_itemcount}" -eq 0 ]
	then
		printf '\n' 1>&2
		printf 'Could not find any repository hosting services.\n' 1>&2
		exit 1
	fi

	# choose list item
	printf '\n'
	if [ "${list_itemcount}" -eq 1 ]
	then
		choice="${list_itemcount}"
		REPOHOSTINGSERVICE="$(printf '%s' "${list}" | cut -d ':' -f "${choice}")"
		printf 'There is only one repository hosting service, therefore nothing to choose.\n'
		printf 'Using "%s".\n' "${REPOHOSTINGSERVICE}"
	elif [ "${choice}" != 'none' ]
	then
		REPOHOSTINGSERVICE="$(printf '%s' "${list}" | cut -d ':' -f "${choice}")"
		printf 'Repository hosting service to use was specified by parameter.\n'
		printf 'Using "%s".\n' "${REPOHOSTINGSERVICE}"
	else
		if [ -n "${OPTION_REPOHOSTINGSERVICE}" ] &&
		   [ "${choice}" = 'none' ]
		then
			OPTION_REPOHOSTINGSERVICE=''
			printf '%s' '-s: ' 1>&2
			printf 'invalid value, ignoring it.' 1>&2
		fi
		printf 'Number identifying the repository hosting service to use? '
		read choice
		choice_ok='0'
		while [ "${choice_ok}" -ne 1 ]
		do
			if [ -z "${choice}" ] ||
			   ! printf '%s' "${choice}" | grep -E -q -e '^[0-9]*$' ||
			   [ "${choice}" -gt "${list_itemcount}" ] ||
			   [ "${choice}" -lt 1 ]
			then
				printf 'Invalid, try again: '
				read choice
				continue 1
			else
				choice_ok='1'
				break 1
			fi
		done
		unset choice_ok
		REPOHOSTINGSERVICE="$(printf '%s' "${list}" | cut -d ':' -f "${choice}")"
	fi

	unset list
	unset choice
	return 0
}


###
# Let the user set the name of the new remote repository ("project name")
#
# This function is setting the global REPOHOSTINGSERVICEPROJECTNAME var. It is
# a helper of the repowizard_start function.
#
# @return integer 0 if executed successfully, 1 otherwise.
repowizard_step2_remotename() {
	local repohostingserviceprojectname_ok

	REPOHOSTINGSERVICEPROJECTNAME='' # init the global var this wizard is for
	if [ -n "${OPTION_REPOHOSTINGSERVICEPROJECTNAME}" ]
	then
		printf '\n'
		printf 'Name of the new remote repository was specified by parameter.\n'
		printf 'Using "%s".\n' "${OPTION_REPOHOSTINGSERVICEPROJECTNAME}"
		REPOHOSTINGSERVICEPROJECTNAME="${OPTION_REPOHOSTINGSERVICEPROJECTNAME}"
	else
		REPOHOSTINGSERVICEPROJECTNAME_DEFAULT="puppet-module-${NEWMODNAME}"
		printf '\n'
		printf '\n'
		printf 'NOTE: most hosting services are restricting their project names alphanumeric\n'
		printf '      characters, underscores and minus; that is, they have to match the\n'
		printf '      pattern '\''^[a-zA-Z0-9_\-]*$'\''\n'
		printf '\n'
		printf 'Please enter the name for your new %s project (just press [ENTER]\n' "${REPOHOSTINGSERVICE}"
		printf 'for "%s"): ' "${REPOHOSTINGSERVICEPROJECTNAME_DEFAULT}"
		read REPOHOSTINGSERVICEPROJECTNAME
		repohostingserviceprojectname_ok='0'
		while [ "${repohostingserviceprojectname_ok}" -ne 1 ]
		do
			if [ -z "${REPOHOSTINGSERVICEPROJECTNAME}" ]
			then
				# use default if user just pressed [ENTER]
				REPOHOSTINGSERVICEPROJECTNAME="${REPOHOSTINGSERVICEPROJECTNAME_DEFAULT}"
			fi
			if ! printf '%s' "${REPOHOSTINGSERVICEPROJECTNAME}" | grep -E -q -e '^[a-zA-Z0-9_\-]*$' # don't forget to update the parameter check if you change something here!
			then
				printf 'Invalid, try again: '
				read REPOHOSTINGSERVICEPROJECTNAME
				continue 1
			else
				 repohostingserviceprojectname_ok='1'
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
# @return integer 0 if executed successfully, 1 otherwise.
repowizard_step3_credentials() {
	local repohostingserviceusername_ok repohostingservicepwd_ok \
	      repohostingserviceorganization_ok

	# username
	REPOHOSTINGSERVICEUSERNAME='' # init the global var this wizard is for
	if [ -n "${OPTION_REPOHOSTINGSERVICEUSERNAME}" ]
	then
		printf '\n'
		printf 'Username for repository hosting service authentication was specified by\n'
		printf 'parameter. Using "%s".\n' "${OPTION_REPOHOSTINGSERVICEUSERNAME}"
		REPOHOSTINGSERVICEUSERNAME="${OPTION_REPOHOSTINGSERVICEUSERNAME}"
	else
		printf '\n'
		printf 'Please enter the username to use to authenticate you on %s: ' "${REPOHOSTINGSERVICE}"
		read REPOHOSTINGSERVICEUSERNAME
		repohostingserviceusername_ok='0'
		while [ "${repohostingserviceusername_ok}" -ne 1 ]
		do
			if [ -z "${REPOHOSTINGSERVICEUSERNAME}" ]
			then
				printf 'Invalid, try again: '
				read REPOHOSTINGSERVICEUSERNAME
				continue 1
			else
				repohostingserviceusername_ok='1'
				break 1
			fi
		done
	fi

	# password
	REPOHOSTINGSERVICEPWD='' # init the global var this wizard is for
	if [ -n "${OPTION_REPOHOSTINGSERVICEPWD}" ]
	then
		printf '\n'
		printf 'Password for repository hosting service authentication was specified by\n'
		printf 'parameter. Using "(password not shown for security reasons)".\n'
		REPOHOSTINGSERVICEPWD="${OPTION_REPOHOSTINGSERVICEPWD}"
	else
		printf '\n'
		printf 'Please enter the password belonging your username to authenticate you\n'
		printf 'on %s (won'\''t be shown for security reasons): ' "${REPOHOSTINGSERVICE}"
		stty -echo
		read REPOHOSTINGSERVICEPWD
		stty echo
		printf '\n'
		repohostingservicepwd_ok='0'
		while [ "${repohostingservicepwd_ok}" -ne 1 ]
		do
			if [ -z "${REPOHOSTINGSERVICEPWD}" ]
			then
				printf 'Invalid, try again: '
				stty -echo
				read REPOHOSTINGSERVICEPWD
				stty echo
				printf '\n'
				continue 1
			else
				repohostingservicepwd_ok='1'
				break 1
			fi
		done
	fi

	# organization
	REPOHOSTINGSERVICEORGANIZATION='' # init the global var this wizard is for
	if [ "${REPOHOSTINGSERVICE}" = 'github' ]
	then
		if [ -n "${OPTION_REPOHOSTINGSERVICEORGANIZATION}" ]
		then
			printf '\n'
			printf 'GitHub Organization your user belongs to was specified by parameter.\n'
			if [ "${OPTION_REPOHOSTINGSERVICEORGANIZATION}" = 'none' ] ||
			   [ "${OPTION_REPOHOSTINGSERVICEORGANIZATION}" = 'false' ]
			then
				REPOHOSTINGSERVICEORGANIZATION=''
				printf 'Using "(none)" (=no organization is used).\n'
			else
				REPOHOSTINGSERVICEORGANIZATION="${OPTION_REPOHOSTINGSERVICEORGANIZATION}"
				printf 'Using "%s".\n' "${OPTION_REPOHOSTINGSERVICEORGANIZATION}"
			fi
		else
			printf '\n'
			printf 'GitHub provides organizations (see http://j.mp/d2PFSw for information). If\n'
			printf 'you want to create the new repository in the organization'\''s account instead\n'
			printf 'of your personal one, you can enter the organization name here. Leave blank\n'
			printf 'for none.\n'
			printf '\n'
			printf 'Please enter the GitHub organization (press [ENTER] if none): '
			read REPOHOSTINGSERVICEORGANIZATION
			repohostingserviceorganization_ok='0'
			while [ "${repohostingserviceorganization_ok}" -ne 1 ]
			do
				if [ -n "${REPOHOSTINGSERVICEORGANIZATION}" ] &&
				   ! printf '%s' "${REPOHOSTINGSERVICEORGANIZATION}" | grep -E -q -e '^[a-zA-Z][a-zA-Z0-9\-]*$' # don't forget to update the parameter check if you change something here!
				then
					printf 'Invalid, try again: '
					read REPOHOSTINGSERVICEORGANIZATION
					continue 1
				else
					repohostingserviceorganization_ok='1'
					break 1
				fi
			done
		fi
	elif [ "${REPOHOSTINGSERVICE}" = 'bitbucket' ]
	then
		if [ -n "${OPTION_REPOHOSTINGSERVICEORGANIZATION}" ]
		then
			printf '\n'
			printf 'Bitbucket Team your user belongs to was specified by parameter.\n'
			if [ "${OPTION_REPOHOSTINGSERVICEORGANIZATION}" = 'none' ] ||
			   [ "${OPTION_REPOHOSTINGSERVICEORGANIZATION}" = 'false' ]
			then
				REPOHOSTINGSERVICEORGANIZATION=''
				printf 'Using "(none)" (=no team is used).\n'
			else
				REPOHOSTINGSERVICEORGANIZATION="${OPTION_REPOHOSTINGSERVICEORGANIZATION}"
				printf 'Using "%s".\n' "${OPTION_REPOHOSTINGSERVICEORGANIZATION}"
			fi
		else
			printf '\n'
			printf 'Bitbucket provides teams (see http://j.mp/LHiSK9 for information). If\n'
			printf 'you want to create the new repository in the teams'\''s account instead\n'
			printf 'of your personal one, you can enter the team name here. Leave blank\n'
			printf 'for none.\n'
			printf '\n'
			printf 'Please enter the Bitbucket team (press [ENTER] if none): '
			read REPOHOSTINGSERVICEORGANIZATION
			repohostingserviceorganization_ok='0'
			while [ "${repohostingserviceorganization_ok}" -ne 1 ]
			do
				if [ -n "${REPOHOSTINGSERVICEORGANIZATION}" ] &&
				   ! printf '%s' "${REPOHOSTINGSERVICEORGANIZATION}" | grep -E -q -e '^[a-zA-Z][a-zA-Z0-9\-]*$' # don't forget to update the parameter check if you change something here!
				then
					printf 'Invalid, try again: '
					read REPOHOSTINGSERVICEORGANIZATION
					continue 1
				else
					repohostingserviceorganization_ok='1'
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
# @return integer 0 if executed successfully, 1 otherwise.
repowizard_step4_repoaccess() {
	local choice_ok

	REPOHOSTINGSERVICEREPOACCESS='' # init the global var this wizard is for
	if [ -n "${OPTION_REPOHOSTINGSERVICEREPOACCESS}" ]
	then
		printf '\n'
		printf 'Who has access to the new remote repository was specified by parameter.\n'
		printf 'Using "%s".\n' "${OPTION_REPOHOSTINGSERVICEREPOACCESS}"
		REPOHOSTINGSERVICEREPOACCESS="${OPTION_REPOHOSTINGSERVICEREPOACCESS}"
	else
		printf '\n'
		printf 'You have to decide who has access to the new remote repository. Please\n'
		printf 'choose the rule you want to use by typing the corresponding number:\n'
		printf '\n'
		printf '  0: public (anyone has read access, e.g. for Open Source)\n'
		printf '  1: private (only you and the people you specify have access)\n'
		printf '\n'
		if [ "${REPOHOSTINGSERVICE}" = 'github' ]
		then
			printf '\033[1mNOTE:\033[0m You need a fitting GitHub plan to be able to create private\n'
			printf '      repositories.\n'
			printf '\n'
		fi
		printf 'Number identifying the access rule to use? '
		read CHOICE
		choice_ok='0'
		while [ "${choice_ok}" -ne 1 ]
		do
			if [ -z "${CHOICE}" ] ||
			   ! printf '%s' "${CHOICE}" | grep -E -q -e '^[0-1]*$'
			then
				printf 'Invalid, try again: '
				read CHOICE
				continue 1
			else
				choice_ok='1'
				break 1
			fi
		done
		unset choice_ok

		if [ "${CHOICE}" -eq 0 ]
		then
			REPOHOSTINGSERVICEREPOACCESS='public' # var we need to process the repo creation
		else
			REPOHOSTINGSERVICEREPOACCESS='private' # var we need to process the repo creation
		fi
		unset CHOICE
	fi
	return 0
}


####
# Creates a repository/project on GitHub.
#
# @return integer 0 if executed successfully, 1 otherwise.
# @link http://developer.github.com/v3/repos/
# @link http://developer.github.com/v3/#authentication
# @link http://blog.httpwatch.com/2009/02/20/how-secure-are-query-strings-over-https/
github_createrepo() {
	local api_targeturl param_name param_description param_private param_issues \
	      param_wiki param_downloads response

	# init
	api_targeturl='https://api.github.com/user/repos'
	param_name="${REPOHOSTINGSERVICEPROJECTNAME}"
	param_description="Puppet module ${NEWMODNAME}"
	param_private='true'
	param_issues='false'
	param_wiki='false'
	param_downloads='false'

	# adjust some parameters
	if [ -n "${REPOHOSTINGSERVICEORGANIZATION}" ]
	then
		api_targeturl="https://api.github.com/orgs/${REPOHOSTINGSERVICEORGANIZATION}/repos"
	fi
	if [ "${REPOHOSTINGSERVICEREPOACCESS}" = 'public' ]
	then
		param_private='false'
	fi

	# let's go
	printf '\n'
	if [ -z "${REPOHOSTINGSERVICEORGANIZATION}" ]
	then
		printf 'Creating GitHub project: %s\n' "${REPOHOSTINGSERVICEUSERNAME}/${REPOHOSTINGSERVICEPROJECTNAME}"
	else
		printf 'Creating GitHub project: %s\n' "${REPOHOSTINGSERVICEORGANIZATION}/${REPOHOSTINGSERVICEPROJECTNAME}"
	fi
	response="$(curl -# --request POST --user "${REPOHOSTINGSERVICEUSERNAME}:${REPOHOSTINGSERVICEPWD}" --data "{\"name\":\"${param_name}\",\"description\":\"${param_description}\",\"private\":${param_private},\"has_issues\":${param_issues},\"has_wiki\":${param_wiki},\"has_downloads\":${param_downloads}}" "${api_targeturl}")"
	if [ $? -eq 7 ] # failed to connect to host.
	then
		printf '\n'
		printf '\033[31mCreating the new project on GitHub failed.\033[0m (failed to connect to host)\n' 1>&2
		printf '\n'
		return 1
	elif [ -z "${response}" ] ||
	     printf '%s' "${response}" | grep -F -q -i -e 'Bad credentials' ||
	     printf '%s' "${response}" | grep -F -q -i -e 'Error'
	then
		printf '\n'
		printf '\033[31mCreating the new project on GitHub failed.\033[0m (maybe bad credentials?)\n' 1>&2
		if [ -n "${response}" ]
		then
			printf 'Original GitHub response:\n' 1>&2
			printf '\n' 1>&2
			printf '%s\n' ${response} 1>&2
			printf '\n' 1>&2
		fi
		return 1
	else
		printf '\033[32mDone.\033[0m\n'
	fi
	return 0
}


####
# Creates a repository on Bitbucket.
#
# @return integer 0 if executed successfully, 1 otherwise.
# @link http://confluence.atlassian.com/display/BITBUCKET/Repositories#Repositories-CreatingaNewRepository
bitbucket_createrepo() {
	local api_targeturl param_name param_description param_private param_issues \
	      param_wiki param_scm param_owner response

	# init
	api_targeturl='https://api.bitbucket.org/1.0/repositories/'
	param_name="${REPOHOSTINGSERVICEPROJECTNAME}"
	param_description="Puppet module ${NEWMODNAME}"
	param_private='true'
	param_issues='false'
	param_wiki='false'
	param_scm="git"
	param_owner="${REPOHOSTINGSERVICEORGANIZATION}"

	# adjust some parameters
	if [ "${REPOHOSTINGSERVICEREPOACCESS}" = 'public' ]
	then
		param_private='false'
	fi

	# let's go
	printf '\n'
	if [ -z "${REPOHOSTINGSERVICEORGANIZATION}" ]
	then
		printf 'Creating Bitbucket project: %s\n' "${REPOHOSTINGSERVICEUSERNAME}/${REPOHOSTINGSERVICEPROJECTNAME}"
	else
		printf 'Creating Bitbucket project: %s\n' "${REPOHOSTINGSERVICEORGANIZATION}/${REPOHOSTINGSERVICEPROJECTNAME}"
	fi
	if [ -z "${REPOHOSTINGSERVICEORGANIZATION}" ]
	then
		response="$(curl -# --request POST --user "${REPOHOSTINGSERVICEUSERNAME}:${REPOHOSTINGSERVICEPWD}" --data "name=${param_name}" --data "is_private=${param_private}" --data "scm=${param_scm}" --data "description=${param_description}" --data "has_issues=${param_issues}" --data "has_wiki=${param_wiki}" "${api_targeturl}")"
	else
		response="$(curl -# --request POST --user "${REPOHOSTINGSERVICEUSERNAME}:${REPOHOSTINGSERVICEPWD}" --data "name=${param_name}" --data "is_private=${param_private}" --data "scm=${param_scm}" --data "description=${param_description}" --data "has_issues=${param_issues}" --data "has_wiki=${param_wiki}" --data "owner=${param_owner}" "${api_targeturl}")"
	fi

	if [ $? -eq 7 ] # failed to connect to host.
	then
		printf '\n'
		printf '\033[31mCreating the new project on Bitbucket failed.\033[0m (failed to connect to host)\n' 1>&2
		printf '\n'
		return 1
	elif [ -z "${response}" ] ||
	     printf '%s' "${response}" | grep -F -q -i -e 'Bad Request' ||
	     printf '%s' "${response}" | grep -F -q -i -e 'Errorlist'
	then
		printf '\n'
		printf '\033[31mCreating the new project on Bitbucket failed.\033[0m (maybe bad credentials?)\n' 1>&2
		if [ -n "${response}" ]
		then
			printf 'Original Bitbucket response:\n' 1>&2
			printf '\n' 1>&2
			printf '%s\n' ${response} 1>&2
			printf '\n' 1>&2
		fi
		return 1
	else
		printf '\033[32mDone.\033[0m\n'
	fi
	return 0
}



################################################################################
# Environment Variables
################################################################################
set +u # allow usage of uninitialized variables

ENV_AUTHOREMAIL=''    # init value of PUPPET_BOILERPLATE_AUTHORFULLNAME
ENV_AUTHORFULLNAME='' # init value of PUPPET_BOILERPLATE_AUTHOREMAIL

# name of the author
ENV_AUTHORFULLNAME="${PUPPET_BOILERPLATE_AUTHORFULLNAME}"

# email address of the author
ENV_AUTHOREMAIL="${PUPPET_BOILERPLATE_AUTHOREMAIL}"
if [ -n "${ENV_AUTHOREMAIL}" ] &&
   ! printf '%s' "${ENV_AUTHOREMAIL}" | grep -F -q -e '@' # don't forget to update the interactive and parameter variable check if you change something here!
then
	ENV_AUTHOREMAIL=''
	printf 'PUPPET_BOILERPLATE_AUTHOREMAIL: invalid value, ignoring it.\n' 1>&2
fi



################################################################################
# Command line arguments
################################################################################
set +u # allow usage of uninitialized variables

OPTION_AUTHORFULLNAME=''                   # init value of -a
OPTION_BOILERPLATE=''                      # init value of -b
OPTION_AUTHOREMAIL=''                      # init value of -e
OPTION_NEWMODNAME=''                       # init value of -n
OPTION_TARGETDIR=''                        # init value of -t
OPTION_REPOHOSTINGSERVICE=''               # init value of -s
OPTION_REPOHOSTINGSERVICEUSERNAME=''       # init value of -u
OPTION_REPOHOSTINGSERVICEPWD=''            # init value of -p
OPTION_REPOHOSTINGSERVICEORGANIZATION=''   # init value of -o
OPTION_REPOHOSTINGSERVICEPROJECTNAME=''    # init value of -q
OPTION_REPOHOSTINGSERVICEREPOACCESS=''     # init value of -r

# parse options
# always helpful: http://rsalveti.wordpress.com/2007/04/03/bash-parsing-arguments-with-getopts/
OPTIND=1
OPTION=''
while getopts ':a:b:e:n:t:s:u:p:o:q:r:h' OPTION
do
	case "${OPTION}" in
		# name of the author
		'a')
			OPTION_AUTHORFULLNAME="${OPTARG}"
			;;

		# boilerplate to use
		'b')
			OPTION_BOILERPLATE="${OPTARG}" # validation will be done by the listing code
			;;

		# email address of the author
		'e')
			OPTION_AUTHOREMAIL="${OPTARG}"
			if ! printf '%s' "${OPTION_AUTHOREMAIL}" | grep -F -q -e '@' # don't forget to update the interactive and environment variable check if you change something here!
			then
				OPTION_AUTHOREMAIL=''
				printf '%s' '-'
				printf '%s: invalid value, ignoring it.' "${OPTION}" 1>&2
			fi
			;;

		# name for the new module
		'n')
			OPTION_NEWMODNAME="${OPTARG}"
			if ! printf '%s' "${OPTION_NEWMODNAME}" | grep -E -q -e '^[a-z][a-z0-9_]*$' # don't forget to update the interactive check if you change something here!
			then
				OPTION_NEWMODNAME=''
				printf '%s' '-'
				printf '%s: invalid value, ignoring it.' "${OPTION}" 1>&2
			fi
			;;

		# targetdir, where to put the new module
		't')
			OPTION_TARGETDIR="${OPTARG}"
			if [ "${OPTION_TARGETDIR}" != '/' ]
			then
				OPTION_TARGETDIR="$(printf '%s' "${OPTION_TARGETDIR}" | sed 's,/$,,')" # strip trailing slash
			fi
			# don't forget to update the interactive check if you change something here!
			if [ ! -d "${OPTION_TARGETDIR}" ]
			then
				OPTION_TARGETDIR=''
				printf '%s' '-'
				printf '%s: invalid value, ignoring it.' "${OPTION}" 1>&2
			fi
			if [ -d "${OPTION_TARGETDIR}/${OPTION_NEWMODNAME}" ] &&
			   [ -n "${OPTION_NEWMODNAME}" ]
			then
				OPTION_TARGETDIR=''
				printf '%s' '-'
				printf '%s: invalid value, ignoring it.' "${OPTION}" 1>&2
			fi
			;;

		# DVCS repository hosting service
		's')
			OPTION_REPOHOSTINGSERVICE="${OPTARG}"
			if [ "${OPTION_REPOHOSTINGSERVICE}" != 'bitbucket' ] &&
			   [ "${OPTION_REPOHOSTINGSERVICE}" != 'github' ]
			then
				OPTION_REPOHOSTINGSERVICE=''
				printf '%s' '-'
				printf '%s: invalid value, ignoring it.' "${OPTION}" 1>&2
			fi
			;;

		# DVCS repository hosting service: username
		'u')
			OPTION_REPOHOSTINGSERVICEUSERNAME="${OPTARG}"
			;;

		# DVCS repository hosting service: password belonging to the username
		'p')
			OPTION_REPOHOSTINGSERVICEPWD="${OPTARG}"
			;;

		# DVCS repository hosting service: organization
		'o')
			OPTION_REPOHOSTINGSERVICEORGANIZATION="${OPTARG}"
			if ! printf '%s' "${OPTION_REPOHOSTINGSERVICEORGANIZATION}" | grep -E -q -e '^[a-zA-Z][a-zA-Z0-9\-]*$' # don't forget to update the interactive check if you change something here!
			then
				OPTION_REPOHOSTINGSERVICEORGANIZATION=''
				printf '%s' '-'
				printf '%s: invalid value, ignoring it.' "${OPTION}" 1>&2
			fi
			;;

		# DVCS repository hosting service: name for the new project
		'q')
			OPTION_REPOHOSTINGSERVICEPROJECTNAME="${OPTARG}"
			if ! printf '%s' "${OPTION_REPOHOSTINGSERVICEPROJECTNAME}" | grep -E -q -e '^[a-zA-Z0-9_\-]*$' # don't forget to update the interactive check if you change something here!
			then
				OPTION_REPOHOSTINGSERVICEPROJECTNAME=''
				printf '%s' '-'
				printf '%s: invalid value, ignoring it.' "${OPTION}" 1>&2
			fi
			;;

		# DVCS repository hosting service: access setting for the new project
		'r')
			OPTION_REPOHOSTINGSERVICEREPOACCESS="${OPTARG}"
			if [ "${OPTION_REPOHOSTINGSERVICEREPOACCESS}" != 'public' ] &&
			   [ "${OPTION_REPOHOSTINGSERVICEREPOACCESS}" != 'private' ]
			then
				OPTION_REPOHOSTINGSERVICEREPOACCESS=''
				printf '%s' '-'
				printf '%s: invalid value, ignoring it.' "${OPTION}" 1>&2
			fi
			;;

		# show help
		'h')
			if ! hash groff > /dev/null 2>&1
			then
				printf 'groff is missing, can'\''t display help.\n' 1>&2
				exit 1
			fi
			FILENAME="$(basename "${0}")"
			# Helpful links about writing and formatting man pages:
			# http://j.mp/L3TcXQ http://j.mp/2buoDa http://j.mp/VNhL5g
			MANPAGE="$(cat << EOF
.TH ${FILENAME} 1
.SH NAME
${FILENAME} \- Tool to create Puppet modules skeletons.

.SH SYNOPSIS
.B ${FILENAME}
.PP
.BI "[\-a " "author-name" "]"
.BI "[\-b " "boilerplate" "]"
.BI "[\-e " "author-email" "]"
.B [\-h]
.BI "[\-n " "module-name" "]"
.BI "[\-t " "target-dir" "]"
.BI "[\-s " "repo-service" "]"
.BI "[\-u " "repo-service-user" "]"
.BI "[\-p " "repo-service-pwd" "]"
.BI "[\-o " "repo-service-org" "]"
.BI "[\-q " "repo-service-project" "]"
.BI "[\-q " "repo-service-access" "]"

.SH DESCRIPTION
Just call this program and follow the instructions. Every value this program
is asking for can be defined as parameter. So it is able to work without user
interaction if all needed values are specified. Invalid values will be ignored
and the user will be asked for a valid value instead.

.SH OPTIONS
.TP
.B \-a
Author name, used for the source code author information of the new module.
.TP
.B \-b
Boilerplate to use (full name, e.g. "application").
.TP
.B \-e
Email address of the author, used for the source code author information of the
new module.
.TP
.B \-h
Print this help.
.TP
.B \-n
Name of the new module. Please note that module names are restricted to
lowercase alphanumeric characters and underscores, and should begin with a
lowercase letter.
.TP
.B \-t
Target directory in which the module shall be copied.
.TP
.B \-s
DVCS repository wizard: Repository hosting service to use. Available: bitbucket,
github.
.TP
.B \-u
DVCS repository wizard: your username on the repository hosting service of
choice.
.TP
.B \-p
DVCS repository wizard: your password belonging to the username on
the repository hosting service of choice.
.B ATTENTION:
Do not use this parameter on multi-user machines! Your password may be listed in
the terminal history, current processes listing, ...
.TP
.B \-o
DVCS repository wizard: Most services provide some kind of multi-user feature
(currently supported: GitHub organizations, Bitbucket teams). You can use this
option if you want to create the repository in such a
multi-user-organization/team account instead of putting the repository in your
personal account. Just submit the name of it by using this option. Use "none"
or "false" as value if there is no organization/team to use. The new repository
will be created in your personal account then.
.TP
.B \-q
DVCS repository wizard: Project name to use for the new repository on the
repository hosting service of choice.
.TP
.B \-r
DVCS repository wizard: access setting for the new project on the repository
hosting service. Available: public, private

.SH ENVIRONMENT VARIABLES
This program uses the following environment variables:
.TP
.B PUPPET_BOILERPLATE_AUTHORFULLNAME
Allows the specification of a default value for the author's name. This var's
value will be ignored if
.B \-a
is set.
.TP
.B PUPPET_BOILERPLATE_AUTHOREMAIL
Allows the specification of a default value for the author's email address. This
var's value will be ignored if
.B \-e
is set.

.SH EXIT STATUS
This script returns a zero exist status if it succeeds. Non zero is returned in
case of failure.

.SH AUTHOR
Andreas Haerter <ah@syn-systems.com>
EOF
)"
			printf '%s\n' "${MANPAGE}" | groff -Tascii -man | more
			unset FILENAME
			unset MANPAGE
			exit 0
			;;

		# unknown/not supported -> kill script and inform user
		*)
			printf 'unknown option "%s". Use "-h" to get usage instructions.' "${OPTARG}" 1>&2
			exit 1
			;;
	esac
done
unset OPTION



################################################################################
# Process
################################################################################
set -u # prevent usage of uninitialized variables

#### welcome user
clear
printf '###############################################################################\n'
printf '# Puppet module creator\n'
printf '###############################################################################\n'


#### check config and environment
if [ ! -d "${DIR_BOILERPLATES}" ]
then
	printf '\n' 1>&2
	printf 'Could not access the boilerplate directory:\n' 1>&2
	printf '%s\n' "${DIR_BOILERPLATES}" 1>&2
	exit 1
fi
if ! hash rsync > /dev/null 2>&1
then
	printf 'rsync is missing, please install it.\n' 1>&2
	exit 1
fi



#### start data wizard
wizard_start


#### copy
printf '\n'
printf '\033[1mCopying boilerplate sources...\033[0m\n'
mkdir -p "${TARGETDIR}" > /dev/null 2>&1
if [ $? -ne 0 ]
then
	printf 'Could not create "%s".\n' "${TARGETDIR}" 1>&2
	exit 1
fi
printf '"%s" -> "%s"\n' "${SOURCEDIR}" "${TARGETDIR}"
rsync --verbose --recursive --whole-file --exclude='DESCRIPTION' --exclude='.git' --exclude='.gitignore' --exclude='.gitattributes' --exclude='.hg' "${SOURCEDIR}/." "${TARGETDIR}/."
if [ $? -ne 0 ]
then
	printf 'Copying to "%s" failed.\n' "${TARGETDIR}" 1>&2
	exit 1
else
	printf '\033[32mDone.\033[0m\n'
fi


#### rename directories
printf '\n'
printf '\033[1mRenaming directories...\033[0m\n'
TOUCHED='0'
IFS_SAVE="${IFS}" # copy current IFS (Internal Field Separator)
IFS="$(printf '\n+')"
for RESOURCE in $(find "${TARGETDIR}" -type d -not -name '\.git' -not -name '\.hg' | grep -F -e "${STR_PLACEHOLDER_BOILERPLATE}" | sort)
do
	# get some data
	RESOURCE_DIR="$(dirname "${RESOURCE}")"
	RESOURCE_OLDNAME="$(basename "${RESOURCE}")"
	RESOURCE_NEWNAME="$(printf '%s' "${RESOURCE_OLDNAME}" | sed -e "s/${STR_PLACEHOLDER_BOILERPLATE}/${NEWMODNAME}/g")"

	# jump to next one if only the path (but not the dir/file itself) matched
	if [ "${RESOURCE_OLDNAME}" = "${RESOURCE_NEWNAME}" ]
	then
		continue 1
	fi

	# rename
	mv -i -v "${RESOURCE_DIR}/${RESOURCE_OLDNAME}" "${RESOURCE_DIR}/${RESOURCE_NEWNAME}"
	if [ $? -ne 0 ]
	then
		printf 'Renaming "%s" failed.\n' "${RESOURCE}" 1>&2
		exit 1
	fi
	TOUCHED='1'

	unset RESOURCE_DIR
	unset RESOURCE_OLDNAME
	unset RESOURCE_NEWNAME
done
if [ "${TOUCHED}" -ne 1 ]
then
	printf 'Nothing to rename, no dirname contains "%s".\n' "${STR_PLACEHOLDER_BOILERPLATE}"
fi
printf '\033[32mDone.\033[0m\n'
IFS="${IFS_SAVE}" # restore IFS (Internal Field Separator)
unset IFS_SAVE
unset RESOURCE
unset TOUCHED


#### rename files
printf '\n'
printf '\033[1mRenaming files...\033[0m\n'
TOUCHED='0'
IFS_SAVE="${IFS}" # copy current IFS (Internal Field Separator)
IFS="$(printf '\n+')"
for RESOURCE in $(find "${TARGETDIR}" -type f -not -wholename '*\/\.git\/*' -not -wholename '*\/\.hg\/*' | grep -F -e "${STR_PLACEHOLDER_BOILERPLATE}" | sort)
do
	# get some data
	RESOURCE_DIR="$(dirname ${RESOURCE})"
	RESOURCE_OLDNAME="$(basename ${RESOURCE})"
	RESOURCE_NEWNAME="$(printf '%s' "${RESOURCE_OLDNAME}" | sed -e "s/${STR_PLACEHOLDER_BOILERPLATE}/${NEWMODNAME}/g")"

	# jump to next one if only the path (but not the dir/file itself) matched
	if [ "${RESOURCE_OLDNAME}" = "${RESOURCE_NEWNAME}" ]
	then
		continue 1
	fi

	# rename
	mv -i -v "${RESOURCE_DIR}/${RESOURCE_OLDNAME}" "${RESOURCE_DIR}/${RESOURCE_NEWNAME}"
	if [ $? -ne 0 ]
	then
		printf 'Renaming "%s" failed.\n' "${RESOURCE}" 1>&2
		exit 1
	fi
	TOUCHED='1'

	unset RESOURCE_DIR
	unset RESOURCE_OLDNAME
	unset RESOURCE_NEWNAME
done
if [ "${TOUCHED}" -ne 1 ]
then
	printf 'Nothing to rename, no filename contains "%s".\n' "${STR_PLACEHOLDER_BOILERPLATE}"
fi
printf '\033[32mDone.\033[0m\n'
IFS="${IFS_SAVE}" # restore IFS (Internal Field Separator)
unset IFS_SAVE
unset RESOURCE
unset TOUCHED


#### replacing file contents
# modulename
printf '\n'
str_rreplace "${STR_PLACEHOLDER_BOILERPLATE}" "${NEWMODNAME}" "${TARGETDIR}" '1'
# author name
printf '\n'
str_rreplace "${STR_PLACEHOLDER_AUTHORFULLNAME}" "${AUTHORFULLNAME}" "${TARGETDIR}" '1'
# author email address
printf '\n'
str_rreplace "${STR_PLACEHOLDER_AUTHOREMAIL}" "${AUTHOREMAIL}" "${TARGETDIR}" '1'
# year placeholder
printf '\n'
str_rreplace "${STR_PLACEHOLDER_CURRENTYEAR}" "$(date +'%Y')" "${TARGETDIR}" '1'


#### user information
printf '\n'
printf '\033[32mThe new module was created successfully.\033[0m\n'
printf '\n'
printf '\n'
printf 'Start to edit the following files (-> positions marked with "\033[1m%s\033[0m")\n' "${STR_PLACEHOLDER_FIXME}"
printf 'for customization:\n'
IFS_SAVE="${IFS}" # copy current IFS (Internal Field Separator)
IFS="$(printf '\n+')"
for RESOURCE in $(grep -R "${STR_PLACEHOLDER_FIXME}" "${TARGETDIR}" | cut -d ":" -f 1 -s | sort | uniq)
do
	printf '%s' '- '
	printf '%s\n' "${RESOURCE}"
done
IFS="${IFS_SAVE}" # restore IFS (Internal Field Separator)
unset IFS_SAVE
unset RESOURCE
printf '\n'
printf '\033[1mBasic work is done, you can start to edit and use the new module now. :-)\033[0m\n'



##### DVCS repository
printf '\n'
printf '\n'
printf 'This program is able to create a new project for your Puppet module on some\n'
printf 'DVCS hosting services. Currently supported:\n'
printf '  - Git repository on GitHub (including GitHub organizations)\n'
printf '  - Git repository on Bitbucket (including Bitbucket teams)\n'
printf '\n'

# Ask user if he wants to start the wizard (unless everything was set by parameters)
if [ -z "${OPTION_REPOHOSTINGSERVICE}" ] ||
   [ -z "${OPTION_REPOHOSTINGSERVICEPROJECTNAME}" ] ||
   [ -z "${OPTION_REPOHOSTINGSERVICEUSERNAME}" ] ||
   [ -z "${OPTION_REPOHOSTINGSERVICEPWD}" ] ||
   [ -z "${OPTION_REPOHOSTINGSERVICEORGANIZATION}" ] ||
   [ -z "${OPTION_REPOHOSTINGSERVICEREPOACCESS}" ]
then
	printf 'Start repository hosting service wizard? [y|n]: '
	read INPUT
	if [ ! "${INPUT}" = 'y' ] &&
	   [ ! "${INPUT}" = 'Y' ] &&
	   [ ! "${INPUT}" = 'j' ] &&
	   [ ! "${INPUT}" = 'J' ]
	then
		printf '\n'
		printf 'Repository hosting wizard canceled by user. Have fun with your new Puppet\n'
		printf 'module.\n'
		printf '\n'
		exit 0
	fi
fi

hash curl > /dev/null 2>&1
if [ $? -ne 0 ]
then
	printf 'curl is missing. Please install it for the next time...\n' 1>&2
	printf 'However: have fun with your new Puppet module.\n' 1>&2
	exit 1
fi
hash git > /dev/null 2>&1
if [ $? -ne 0 ]
then
	printf 'git is missing. Please install it for the next time...\n' 1>&2
	printf 'However: have fun with your new Puppet module.\n' 1>&2
	exit 1
fi


#### start repository data wizard
repowizard_start


#### create remote project on repository hosting service
REMOTECREATE_SUCCESS='0'
while [ "${REMOTECREATE_SUCCESS}" -ne 1 ]
do
	if [ "${REPOHOSTINGSERVICE}" = 'github' ]
	then
		github_createrepo
		if [ $? -eq 0 ]
		then
			REMOTECREATE_SUCCESS='1'
		fi
	elif [ "${REPOHOSTINGSERVICE}" = 'bitbucket' ]
	then
		bitbucket_createrepo
		if [ $? -eq 0 ]
		then
			REMOTECREATE_SUCCESS='1'
		fi
	else
		printf '"%s" is an unknown service.\n' "${REPOHOSTINGSERVICE}" 1>&2
		exit 1
	fi

	if [ "${REMOTECREATE_SUCCESS}" -ne 1 ]
	then
		RETRY='n'
		printf 'Retry? [y|n]: '
		read RETRY
		if [ "${RETRY}" = 'y' ] ||
		   [ "${RETRY}" = 'Y' ] ||
		   [ "${RETRY}" = 'j' ] ||
		   [ "${RETRY}" = 'J' ]
		then
			continue 1
		fi
		unset RETRY

		RESTARTWIZARD="n"
		printf 'Restart DVCS wizard? (e.g. correct wrong data, retry afterwards) [y|n]: '
		read RESTARTWIZARD
		if [ "${RESTARTWIZARD}" = 'y' ] ||
		   [ "${RESTARTWIZARD}" = 'Y' ] ||
		   [ "${RESTARTWIZARD}" = 'j' ] ||
		   [ "${RESTARTWIZARD}" = 'J' ]
		then
			repowizard_start
			continue 1
		else
			printf '\n'
			printf 'Repository creation canceled by user. However, have fun with your new\n'
			printf 'Puppet module (nothing was modified by the DVCS wizard there, no need\n'
			printf 'to restart the whole module creation).\n'
			printf '\n'
			exit 0
		fi
		unset RESTARTWIZARD
	fi
done


#### create local repository
printf '\n'
printf 'Creating local git repository in "%s"\n' "${TARGETDIR}"
git init "${TARGETDIR}" > /dev/null 2>&1 #note: running git init in an existing repository is safe.
if [ $? -ne 0 ]
then
	printf '"git init" failed for "%s"!\n' "${TARGETDIR}" 1>&2
	printf 'However, your new Puppet module should be OK. Just create the repository\n' 1>&2
	printf 'by hand. Alternatively, delete everything and re-start the module creation.\n' 1>&2
	printf '\n'
	exit 1
fi
printf '\033[32mDone.\033[0m\n'


#### add git remote
printf '\n'
if [ "${REPOHOSTINGSERVICE}" = 'github' ]
then
	printf 'Adding GitHub repository as git remote origin...\n'
	if [ -z "${REPOHOSTINGSERVICEORGANIZATION}" ]
	then
		git --git-dir="${TARGETDIR}/.git" --work-tree="${TARGETDIR}" remote add origin "git@github.com:${REPOHOSTINGSERVICEUSERNAME}/${REPOHOSTINGSERVICEPROJECTNAME}.git" > /dev/null 2>&1
	else
		git --git-dir="${TARGETDIR}/.git" --work-tree="${TARGETDIR}" remote add origin "git@github.com:${REPOHOSTINGSERVICEORGANIZATION}/${REPOHOSTINGSERVICEPROJECTNAME}.git" > /dev/null 2>&1
	fi
	if [ $? -ne 0 ]
	then
		printf '"git remote add origin" failed for "%s"!\n' "${TARGETDIR}" 1>&2
		printf 'However, your new Puppet module should be OK. Just configure git remote\n' 1>&2
		printf 'by hand. Alternatively, delete everything and re-start the module creation.\n' 1>&2
		printf '\n'
		exit 1
	fi
	printf 'You may want to use "git push -u origin master" after your first commit.\n'
	printf '\033[32mDone.\033[0m\n'
elif [ "${REPOHOSTINGSERVICE}" = 'bitbucket' ]
then
	printf 'Adding Bitbucket repository as git remote origin...\n'
	if [ -z "${REPOHOSTINGSERVICEORGANIZATION}" ]
	then
		git --git-dir="${TARGETDIR}/.git" --work-tree="${TARGETDIR}" remote add origin "git@bitbucket.org:${REPOHOSTINGSERVICEUSERNAME}/${REPOHOSTINGSERVICEPROJECTNAME}.git" > /dev/null 2>&1
	else
		git --git-dir="${TARGETDIR}/.git" --work-tree="${TARGETDIR}" remote add origin "git@bitbucket.org:${REPOHOSTINGSERVICEORGANIZATION}/${REPOHOSTINGSERVICEPROJECTNAME}.git" > /dev/null 2>&1
	fi
	if [ $? -ne 0 ]
	then
		printf '"git remote add origin" failed for "%s"!\n' "${TARGETDIR}" 1>&2
		printf 'However, your new Puppet module should be OK. Just configure git remote\n' 1>&2
		printf 'by hand. Alternatively, delete everything and re-start the module creation.\n' 1>&2
		printf '\n'
		exit 1
	fi
	printf 'You may want to use "git push -u origin master" after your first commit.\n'
	printf '\033[32mDone.\033[0m\n'
else
	printf '"%s" is an unknown service.\n' "${REPOHOSTINGSERVICE}" 1>&2
	exit 1
fi


printf '\n'
printf '\033[1mThe %s project and the local repository were created successfully.\033[0m\n' "${REPOHOSTINGSERVICE}"
printf '\n'
exit 0

