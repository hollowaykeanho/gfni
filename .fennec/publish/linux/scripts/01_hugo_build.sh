#!/bin/bash
################################
# User Variables               #
################################
VERSION="1.0.0"
PUBLISH_PATH="${PUBLISH_PATH:-"public"}"
SITE_PATH="${SITE_PATH:-".sites"}"

################################
# App Variables                #
################################
action=""
current_path="$PWD"
manager_script="manager.sh"
site_path="${current_path}/${SITE_PATH}"
publish_path="${current_path}/${PUBLISH_PATH}"

################################
# Functions                    #
################################
print_version() {
	echo $VERSION
}

_check_dependency() {
	if [ "$(which hugo)" = "" ]; then
		1>&2 echo "[ ERROR ] missing hugo. Did you install hugo base?"
		exit 1
	fi

	if [ ! -d "$site_path" ]; then
		1>&2 echo "[ ERROR ] missing hugo build directory: $site_path"
		exit 1
	fi
}

_build() {
	cd "$site_path"
	if [ -f "${PWD}/$manager_script" ]; then
		/bin/bash "${PWD}/$manager_script" -B clean
	else
		hugo --minify
		2>&1 mv ${PWD}/public "$publish_path" > /dev/null
	fi
	cd "$current_path"

	if [ ! -d "$publish_path" ]; then
		1>&2 echo "[ ERROR ] $publish_path not found. Build failed."
		exit 1
	fi
}

run() {
	_check_dependency
	_build
}

################################
# CLI Parameters and Help      #
################################
print_help() {
	echo "\
HUGO Site Generator
The program to check dependencies for hugo site generations
-------------------------------------------------------------------------------
To use: $0 [ACTION] [ARGUMENTS]

ACTIONS
1. -h, --help			print help. Longest help is up
				to this length for terminal
				friendly printout.

2. -r, --run			run the program.

3. -v, --version		print app version.

4. -s, --site-path		state the site resources path. It
				is used for generating the public
				output files.
				COMPULSORY VALUES:
				1. -s /path/to/sites

5. -p, --publish-path		state the publish directory path.
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
-s|--site-path)
	if [[ "$2" != "" && "${2:0:1}" != "-" ]]; then
		SITE_PATH="${@:2}"
		shift 1
	fi
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
