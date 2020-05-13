#!/bin/bash
################################
# User Variables               #
################################
VERSION="1.0.0"

################################
# App Variables                #
################################
action=""
current_path="$PWD"
workspace="${current_path}/tmp"

################################
# Functions                    #
################################
print_version() {
	echo $VERSION
}

run() {
	if [[ "$HUGO_VERSION" == "" ]]; then
		return 0
	fi
	1>&2 echo "[ INFO ] HUGO_VERSION detected. Begin Installation."

	# setup variables
	case "$(uname -m)" in
	x86_64)
		arch="64bit"
		;;
	i386|i686)
		arch="32bit"
		;;
	armv7l)
		arch="ARM"
		;;
	armv8)
		arch="ARM64"
		;;
	*)
		1>&2 echo "[ ERROR ] unknown CPU op-mode from architecture."
		;;
	esac

	case "$(uname -s)" in
	Linux)
		machine="Linux"
		;;
	Darwin)
		machine="macOS"
		;;
	FreeBSD)
		machine="freeBSD"
		;;
	NetBSD)
		machine="NetBSD"
		;;
	DragonFly)
		machine="DragonFlyBSD"
		;;
	OpenBSD)
		machine="OpenBSD"
		;;
	*)
		1>&2 echo "[ ERROR ] unknown operating system."
		exit 1
		;;
	esac
	hugo_pack="hugo_extended_${HUGO_VERSION}_${machine}-${arch}.tar.gz"
	hugo_url="https://github.com/gohugoio/hugo/releases/download"
	hugo_url="${hugo_url}/v${HUGO_VERSION}/${hugo_pack}"
	hugo_output="/usr/bin/hugo"

	# cleanup
	rm -rf "$workspace" > /dev/null
	mkdir -p "$workspace"
	cd "$workspace"

	# download
	curl --silent --fail --location --remote-name "$hugo_url"
	if [[ "$?" != "0" || ! -f "./$hugo_pack" ]]; then
		1>&2 echo "[ ERROR ] download failed."
		exit 1
	fi

	# unpack package
	tar -xzf "./$hugo_pack"
	rm "./$hugo_pack"

	# install package
	sudo mv hugo "$hugo_output"

	# cleanup workspace
	cd ..
	rm -rf "$workspace" > /dev/null
	1>&2 echo "[ INFO ] HUGO installed."
}

################################
# CLI Parameters and Help      #
################################
print_help() {
	echo "\
HUGO Installer
The one script to install a usable HUGO
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
