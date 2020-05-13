#!/bin/bash
################################
# User Variables               #
################################
VERSION="1.7.0"

################################
# App Variables                #
################################
_action=""
_current_directory="$PWD"
_theme_directory="${_current_directory}/themes"
_theme_config="${_theme_directory}/.themes"
_hostname="localhost"
_port="8080"
_mode=""

################################
# Functions                    #
################################
_print_status() {
	_status_mode="$1" && shift 1

	# process status message
	_status_message=""
	case "$_status_mode" in
	error)
		_status_message="[ ERROR ] $@"
		;;
	warning)
		_status_message="[ WARNING ] $@"
		;;
	debug)
		if [ -z ${DEBUG+x} ]; then
			return 0
		fi
		_status_message="[ DEBUG ] $@"
		;;
	info)
		_status_message="[ INFO ] $@"
		;;
	plain)
		_status_message="$@"
		;;
	*)
		return 0
		;;
	esac

	1>&2 echo "${_status_message}"
}

print_version() {
	echo $VERSION
}

_check_dependency() {
	_print_status info "checking dependencies' availability."

	_print_status debug "checking Git"
	if [ "$(which git)" = "" ]; then
		_print_status error "missing git program."
		exit 1
	fi

	_print_status debug "checking Hugo"
	if [ "$(which hugo)" = "" ]; then
		_print_status error "missing hugo program."
		exit 1
	fi

	ret="$(hugo version | grep extended)"
	if [ -z "$ret" ]; then
		_print_status error "you need Hugo extended version."
		exit 1
	fi
}

_check_location() {
	_print_status info "checking current directory validity."
	if [ ! -f "${_current_directory}/manager.sh" ] || \
		[ ! -d "$_theme_directory" ]; then
		_print_status error "not in hugo directory."
		exit 1
	fi
	_print_status info "done"
}

_get_themes() {
	_print_status info "getting all listed themes."
	if [ ! -f "$_theme_config" ]; then
		_print_status error "missing .themes file."
		exit 1
	fi

	old_IFS="$IFS"
	while IFS='' read -r line || [ -n "$line" ]; do
		if [ "${line:0:1}" = "#" ]; then
			continue
		fi

		_url="${line%% *}"
		_remainder="${line#* }"
		_branch="${_remainder%% *}"
		_remainder="${_remainder#* }"
		_tag=""
		if [ "$_remainder" != "$_branch" ]; then
			_tag="${_remainder%% *}"
		fi


		_print_status debug "
url   : ${_url}
branch: ${_branch}
tag   : ${_tag}"
		if [ "$_url" = "" ] || \
			[ "$_branch" = "" ]; then
			continue
		fi

		_print_status info "detected $_url. Setting up now."

		_theme_name="${_url##*/}"
		_theme_path="${_theme_directory}/${_theme_name}"
		if [ ! -d "$_theme_path" ]; then
			cd "$_theme_directory"
			git clone "$_url"
		fi

		cd "${_theme_path}"
		git checkout "$_branch"
		git pull
		if [ "$_tag" != "" ]; then
			git checkout tags/"$_tag"
		fi
		if [ $? -ne 0 ]; then
			_print_status error ""
			exit 1
		fi
		cd "$_current_directory"

		_print_status info "done.
"

	done < "$_theme_config"
	IFS="$old_IFS" && unset old_IFS
}

setup() {
	_check_location
	_check_dependency
	_get_themes
}

_launch_server() {
	_print_status info "launching hugo server"

	_print_status debug "
HOSTNAME: $_hostname
PORT    : $_port
"
	hugo server --buildDrafts \
		--disableFastRender \
		--bind "$_hostname" \
		--baseURL "$_hostname" \
		--port "$_port"
}

run() {
	_check_location
	_check_dependency
	_launch_server
}

_shift_404() {
	# get publish directory path
	config_path="./config/_default/config.toml"
	ret=""
	old_IFS="$IFS"
	while IFS='' read -r line || [ -n "$line" ]; do
		if [[ "$line" == *publishDir* ]]; then
			ret="$line"
			break
		fi
	done < "$config_path"
	IFS="$old_IFS" && unset old_IFS

	ret="${ret#*\"}"
	publishDir="${ret%%\"*}"
	if [ "$publishDir" == "" ]; then
		_print_status warning "unable to copy 404: bad publishDir."
		return 0
	fi


	# get primary language path
	config_path="./config/_default/languages.toml"
	ret=""
	old_IFS="$IFS"
	while IFS='' read -r line || [ -n "$line" ]; do
		if [[ "$line" == [* ]]; then
			ret="$line"
			break
		fi
	done < "$config_path"
	IFS="$old_IFS" && unset old_IFS

	ret="${ret#*[}"
	lang="${ret%%]*}"
	if [ "$lang" == "" ]; then
		_print_status warning "unable to copy 404: missing lang-code."
		return 0
	fi


	# copy 404.html to root location
	ret=($(find "$publishDir" -type f -name '404.html' | grep "$lang"))
	if [ "${#ret[@]}" != "0" ]; then
		_print_status info "copying ${ret[0]} to ${publishDir}/404.html"
		cp "${ret[0]}" "${publishDir}/404.html"
	fi

	unset ret lang publishDir
}

_compile() {
	_print_status info "building hugo artifacts"
	hugo --minify
	_shift_404
	_print_status info "done"
}

build() {
	_check_location
	_check_dependency

	case "$_mode" in
	clean)
		setup
		_compile
		;;
	*)
		_compile
		;;
	esac
}

get_date() {
	date +"%Y-%m-%dT%T%:z"
}

################################
# CLI Parameters and Help      #
################################
print_help() {
	echo "\
Bissetii Theme Hugo Manager
One script to handle Hugo repository with Bissetii theme.
-------------------------------------------------------------------------------
To use: $0 [ACTION] [ARGUMENTS]

ACTIONS
1. -h, --help			print help. Longest help is up
				to this length for terminal
				friendly printout.

2. -v, --version		print app version.

3. -s, --setup			perform the engine setup like themes downloads.
				OPTIONAL ARGUMENTS
				 1. -d, --debug
					enable debug printout.

4. -r, --run			start a development server.
				OPTIONAL ARGUMENTS
				 1. -b, --bind
					hostname or domain name.
					Default is 'localhost'
					Example:
					./manager.sh -r -b 'http://example.com'

				 2. -p, --port
					port number.
					Default is '8080'
					Example:
					./manager.sh -r -p 12345

				 3. -d, --debug
					enable debug printout.

5. -B, --build			build the Hugo static sites.
				OPTIONAL VALUES
				1. -B <no value>
					perform a quick build. This assumes the
					repository is setup correctly and will
					skip the setup stage.

				2. -B clean
					perform a clean build which includes
					setting up the entire repository.

				OPTIONAL ARGUMENTS
				1. -d, --debug
					enable debug printout.

6. -D, --date			get Hugo compatible date.
"
}

run_action() {
case "$_action" in
"b")
	build
	;;
"r")
	run
	;;
"s")
	setup
	;;
"h")
	print_help
	;;
"v")
	print_version
	;;
"d")
	get_date
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
-d|--debug)
	DEBUG=true
	;;
-b|--bind)
	if [[ "$2" != "" && "${2:0:1}" != "-" ]]; then
		_hostname="$2"
		shift 1
	fi
	;;
-p|--port)
	if [[ "$2" != "" && "${2:0:1}" != "-" ]]; then
		_port="$2"
		shift 1
	fi
	;;
-B|--build)
	_action="b"
	if [[ "$2" != "" && "${2:0:1}" != "-" ]]; then
		_mode="$2"
		shift 1
	fi
	;;
-D|--date)
	_action="d"
	;;
-r|--run)
	_action="r"
	;;
-s|--setup)
	_action="s"
	;;
-h|--help)
	_action="h"
	;;
-v|--version)
	_action="v"
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
