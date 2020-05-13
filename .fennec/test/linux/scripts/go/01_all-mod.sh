#!/bin/bash
################################
# User Variables               #
################################
VERSION="1.0.0"
go_coverage_mode="count"

################################
# App Variables                #
################################
action=""
repo_name=""
test_directory=".tests"
works_directory="${test_directory}/works"
results_directory="${test_directory}/results"
coverage_profile="${results_directory}/profiles"


################################
# Functions                    #
################################
_print_status() {
	mode="$1"
	message="${@:2}"

	case "$mode" in
	error)
		1>&2 echo "[ ERROR ] $message"
		;;
	warning)
		1>&2 echo "[ WARNING ] $message"
		;;
	*)
		1>&2 echo "[ INFO ] $message"
		;;
	esac
}

print_version() {
	echo $VERSION
}

_prepare_test_directory() {
	rm -rf "$works_directory" > /dev/null
	rm -rf "$results_directory" > /dev/null
	mkdir -p "$results_directory"
	mkdir -p "$works_directory"
}

_get_coverage_data() {
	packages_list=($(go list ./...))

	for package in "${packages_list[@]}"; do
		subject="${works_directory}/${package//\//-}.cover"
		go test -covermode="$go_coverage_mode" \
			-coverprofile="$subject" \
			"$package"
	done

	echo "mode: $go_coverage_mode" > "$coverage_profile"
	grep -h -v "^mode:" "$works_directory"/*.cover >> "$coverage_profile"
}

_present_coverage_report() {
	case "$1" in
	*)
		go tool cover -func="$coverage_profile"
		;;
	esac
}

call_report_card() {
	if [[ "$(which curl)" == "" ]]; then
		_print_status "error" "curl program is missing. Please install."
		exit 1
	fi

	if [[ "$repo_name" == "" ]]; then
		_print_status "error" "empty repo_name"
		exit 1
	fi

	url="https://goreportcard.com/checks"
	_print_status "info" "calling goreportcard.com for $repo_name"
	repo_name="${repo_name////%2F}"
	curl --fail --location --silent \
		--header "Content-Type: application/x-www-form-urlencoded" \
		--data "repo=$repo_name" \
		--request POST "$url" > /dev/null
	ret=$?
	if [[ "$ret" == "0" ]]; then
		_print_status "info" "call successful."
		return 0
	fi
	_print_status "error" "call failed."
}

run() {
	_prepare_test_directory
	_get_coverage_data
	_present_coverage_report
}

################################
# CLI Parameters and Help      #
################################
print_help() {
	echo "\
GO TEST COVERAGE AUTOMATOR
The semi-automatic script for automating to go test coverage for multiple
packages.
-------------------------------------------------------------------------------
To use: $0 [ACTION] [ARGUMENTS]

ACTIONS
1. -h, --help			print help. Longest help is up
				to this length for terminal
				friendly printout.

2. -v, --version		print app version.

3. -r, --run			run the test.

4. -rc, --report-card		call the goreportcard.com to
				run a test for the given
				repository.
				COMPULSORY VALUE:
				-rc <repo import path>
					the repository import
					path.

				EXAMPLE:
				-rc gitlab.com/zoralab/cerigo
"
}

run_action() {
case "$action" in
"rc")
	call_report_card
	;;
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
	return 1
	;;
esac
}

process_parameters() {
while [[ $# != 0 ]]; do
case "$1" in
-rc|--report-card)
	if [[ "$2" != "" && "${2:0:1}" != "-" ]]; then
		repo_name="$2"
		shift 1
	fi
	action="rc"
		;;
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
