#!/bin/bash
################################
# User Variables               #
################################
VERSION="1.1.0"

################################
# App Variables                #
################################
action=""
current_path="$PWD"
workspace="${PWD}/tmp"
installer=""
sudoer=""

################################
# Functions                    #
################################
print_version() {
	echo $VERSION
}

_find_installer() {
	if [ ! "$(which apt-get)" = "" ]; then
		installer="apt-get"
		return 0
	fi

	if [ ! "$(which apt)" = "" ]; then
		installer="apt"
		return 0
	fi

	if [ ! "$(which yum)" = "" ]; then
		installer="yum"
		return 0
	fi

	1>&2 echo "[ ERROR ] missing package manager."
	exit 1
}

_check_root() {
	if [ "$(whoami)" = "root" ]; then
		sudoer=""
		return 0
	fi

	if [ ! "$(which sudo)" = "" ]; then
		2>&1 sudo echo > /dev/null
		if [ $? -eq 0 ]; then
			sudoer="sudo"
			return 0
		fi
	fi
	1>&2 echo "[ ERROR ] problem with root access."
	exit 1
}

run() {
	if [ "$REPO_MAKEFILE" == "" ]; then
		return 0
	fi
	1>&2 echo "[ INFO ] REPO_MAKEFILE detected. Begin Installation."

	# check dependencies
	_find_installer
	_check_root

	# install package
	if [ "$sudoer" = "" ]; then
		_installer_command="$installer"
	else
		_installer_command="sudo $installer"
	fi

	$_installer_command install make -y
}

################################
# CLI Parameters and Help      #
################################
print_help() {
	echo "\
Makefile Installer
The one script to install a usable Makefile with Make
-------------------------------------------------------------------------------
To use: $0 [ACTION] [ARGUMENTS]

ACTIONS
1. -h, --help			print help. Longest help is up
				to this length for terminal
				friendly printout.

2. -r, --run			run the installer program.

2. -v, --version		print app version.
"
}

run_action() {
case "$action" in
"h")
	print_help
	;;
"v")
	print_version
	;;
"r"|*)
	run
	;;
esac
}

process_parameters() {
while [[ $# != 0 ]]; do
case "$1" in
-r|--run)
	action="r"
	;;
-h|--help)
	action="h"
	;;
-v|--version)
	action="v"
	;;
*)
	;;
esac
shift 1
done
}

main() {
	process_parameters $@
	run_action
	if [[ $? != 0 ]]; then
		exit 1
	fi
}

if [[ $BASHELL_TEST_ENVIRONMENT != true ]]; then
	main $@
fi
