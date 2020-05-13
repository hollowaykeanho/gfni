#!/bin/bash
################################
# User Variables               #
################################
VERSION="1.0.0"
PUBLISH_PATH="${PUBLISH_PATH:-"public"}"

################################
# App Variables                #
################################
action=""
current_path="$PWD"
publish_path="${current_path}/$PUBLISH_PATH"

################################
# Functions                    #
################################
print_version() {
	echo $VERSION
}

run() {
	if [ ! -d "$publish_path" ]; then
		1>&2 echo "[ ERROR ] no publishing output: $publish_path"
		exit 1
	fi
}

################################
# CLI Parameters and Help      #
################################
print_help() {
	echo "\
DUMP Publish Checker
The program to check a publishing directory for static hosting.
-------------------------------------------------------------------------------
To use: $0 [ACTION] [ARGUMENTS]

ACTIONS
1. -h, --help			print help. Longest help is up
				to this length for terminal
				friendly printout.

2. -r, --run			run the program.

3. -v, --version		print app version.

4. -p, --publish-path		state the publish directory path.
				It is used to host the sites.
				COMPULSORY VALUES:
				1. -p /path/to/public
"
}

run_action() {
case "$action" in
"r")
	run
	;;
"h")
	print_help
	;;
"v")
	print_version
	;;
*)
	echo "[ ERROR ] - invalid command."
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
-p|--publish-path)
	if [[ "$2" != "" && "${2:0:1}" != "-" ]]; then
		PUBLISH_PATH="${@:2}"
		shift 1
	fi
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
