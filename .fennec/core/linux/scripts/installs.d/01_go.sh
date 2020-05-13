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
	if [[ "$GO_VERSION" == "" ]]; then
		return 0
	fi
	1>&2 echo "[ INFO ] GO_VERSION detected. Begin Installation."

	# setup variables
	case "$(uname -m)" in
	x86_64)
		arch="amd64"
		;;
	i386|i686)
		arch="i386"
		;;
	*)
		1>&2 echo "[ ERROR ] unknown CPU architecture."
		exit 1
		;;
	esac

	case "$(uname -s)" in
	Linux)
		machine="linux"
		;;
	*)
		1>&2 echo "[ ERROR ] unsupported OS."
		exit 1
		;;
	esac

	go_pack="go${GO_VERSION}.${machine}-${arch}.tar.gz"
	go_url="https://dl.google.com/go/$go_pack"
	export GOPATH="${GOPATH:-"/builds"}"
	export GOROOT="${GOROOT:-"/usr/local/go"}"
	export GOBIN="${GOBIN:-"/bin"}"

	# cleanup
	sudo rm -rf "$GOROOT" > /dev/null
	rm -rf "$workspace" > /dev/null
	mkdir -p "$workspace"
	cd "$workspace"

	# download
	curl --silent --fail --location --remote-name "$go_url"
	if [[ $? != 0 || ! -f "./$go_pack" ]]; then
		1>&2 echo "[ ERROR ] download failed."
		exit 1
	fi

	# unpack package
	tar -xzf "./$go_pack"
	rm "./$go_pack"

	# install package
	sudo mv go "${GOROOT%/*}"
	mkdir -p "${GOPATH}/src"
	mkdir -p "${GOPATH}/pkg"
	mkdir -p "$GOBIN"
	export PATH="$PATH:${GOROOT}/bin:${GOBIN}"

	# cleanup workspace
	cd ..
	rm -rf "$workspace" > /dev/null
	1>&2 echo "[ INFO ] Go installed."
}

################################
# CLI Parameters and Help      #
################################
print_help() {
	echo "\
Go Installer
The one script to install a usable GO
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
