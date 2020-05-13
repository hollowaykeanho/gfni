#!/bin/bash
################################
# User Variables               #
################################
VERSION="1.0.0"
INSTALLER="${INSTALLER:-""}"

################################
# App Variables                #
################################
action=""
setup_scripts_directory="${BASH_SOURCE[0]%/*}/installs.d"

################################
# Functions                    #
################################
print_version() {
	echo $VERSION
}

_print_status() {
	status_mode="$1" && shift 1

	# process status message
	status_message=""
	case "$status_mode" in
	error)
		status_message="[ ERROR ] $@"
		;;
	warning)
		status_message="[ WARNING ] $@"
		;;
	debug)
		if [ -z ${DEBUG+x} ]; then
			return 0
		fi
		status_message="[ DEBUG ] $@"
		;;
	info)
		status_message="[ INFO ] $@"
		;;
	*)
		return 0
		;;
	esac

	# print status
	1>&2 echo "$status_message"
}

_identify_installer() {
	if [[ "$INSTALLER" != "" ]]; then
		return 0
	fi

	if [[ "$(which apt-get)" != "" ]]; then
		export INSTALLER="apt-get"
		return 0
	fi

	if [[ "$(which yum)" != "" ]]; then
		export INSTALLER="yum"
		return 0
	fi

	_print_status error "unknown linux operating system package manager"
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
	_print_status error "problem with root access. Access denied."
	exit 1
}

_prepare_system() {
	if [ "$sudoer" = "" ]; then
		_installer_command="$INSTALLER"
	else
		_installer_command="sudo $INSTALLER"
	fi
	"$_installer_command" update -y
	"$_installer_command" upgrade -y
	export PATH="${PATH}:./bin"
}

_execute_setup() {
	if [ ! -d "$setup_scripts_directory" ]; then
		_print_status error "missing setup scripts directory"
		exit 1
	fi

	for setup_script in "$setup_scripts_directory"/* ; do
		[ -e "$setup_script" ] || continue
		/bin/bash "$setup_script"
	done
}

run() {
	_identify_installer
	_check_root
	_prepare_system
	_execute_setup
}


################################
# CLI Parameters and Help      #
################################
print_help() {
	echo "\
Base Installer
The one script to setup and run all the setup scripts.
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
"r")
	run
	;;
*)
	_print_status error "invalid command."
	exit 1
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
