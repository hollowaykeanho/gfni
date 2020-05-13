#!/bin/bash
################################
# User Variables               #
################################
GITLAB_PRIVATE_TOKEN="$GITLAB_PRIVATE_TOKEN"
GITLAB_NAMESPACE="$GITLAB_NAMESPACE"
GITLAB_PROJECT_NAME="$GITLAB_PROJECT_NAME"

################################
# App Variables                #
################################
version="0.1.0"
action=""
fennec_path=""
gitlab_api_path=""
gitlab_api_config_path=""
gitlab_id=""
domain=""
ssl_pem_path=""
ssl_key_path=""

################################
# Functions                    #
################################
print_version() {
	echo $version
}

prepare_parameters() {
	if [[ ! -d "${PWD}/.fennec" ]]; then
		1>&2 echo "[ ERROR ] fennec directory is missing."
		exit 1
	fi
	fennec_path="${PWD}"
	gitlab_api_path="${fennec_path}/.fennec/api/gitlab"
	gitlab_api_config_path="${gitlab_api_path}/config.sh"
	if [[ ! -f "$gitlab_api_config_path" ]]; then
		1>&2 echo "[ ERROR ] missing config: $gitlab_api_config_path"
		exit 1
	fi

	. "$gitlab_api_config_path"

	if [[ "$GITLAB_API_URL" == "" ]]; then
		1>&2 echo "[ ERROR ] GITLAB_API_URL is missing."
		exit 1
	fi

	if [[ "$(which curl)" == "" ]]; then
		1>&2 echo "[ ERROR ] curl package is not installed."
		exit 1
	fi

	if [[ "$GITLAB_PRIVATE_TOKEN" == "" ]]; then
		1>&2 echo "[ ERROR ] missing GITLAB_PRIVATE_TOKEN."
		exit 1
	fi

	if [[ "$GITLAB_NAMESPACE" == "" ]]; then
		1>&2 echo "[ ERROR ] missing GITLAB_NAMESPACE."
		exit 1
	fi

	if [[ "$GITLAB_PROJECT_NAME" == "" ]]; then
		1>&2 echo "[ ERROR ] missing GITLAB_PROJECT_NAME."
		exit 1
	fi

	gitlab_id="${GITLAB_NAMESPACE}%2F${GITLAB_PROJECT_NAME}"
}

list_all_domains() {
	url="${GITLAB_API_URL}/pages/domains"
	curl --fail \
		--header "PRIVATE-TOKEN: $GITLAB_PRIVATE_TOKEN" \
		--request GET "$url"
}

list_all_project_pages_domains() {
	url="${GITLAB_API_URL}/projects/${gitlab_id}/pages/domains"
	curl --fail \
		--header "PRIVATE-TOKEN: $GITLAB_PRIVATE_TOKEN" \
		--request GET "$url"
}

get_pages_domain() {
	if [[ "$domain" == "" ]]; then
		echo "[ ERROR ] missing domain. Please specify one."
		exit 1
	fi

	url="${GITLAB_API_URL}/projects/${gitlab_id}/pages/domains/${domain}"
	curl --fail \
		--header "PRIVATE-TOKEN: $GITLAB_PRIVATE_TOKEN" \
		--request GET "$url"
}

create_pages_domain() {
	if [[ "$domain" == "" ]]; then
		echo "[ ERROR ] missing domain. Please specify one."
		exit 1
	fi
	url="${GITLAB_API_URL}/projects/${gitlab_id}/pages/domains"

	if [[ ! -f "$ssl_pem_path" || ! -f "$ssl_key_path" ]]; then
		curl --fail \
			--header "PRIVATE-TOKEN: $GITLAB_PRIVATE_TOKEN" \
			--form "domain=$domain" \
			--request POST "$url"
		exit $?
	fi

	curl --fail \
		--header "PRIVATE-TOKEN: $GITLAB_PRIVATE_TOKEN" \
		--form "domain=$domain" \
		--form "certificate=@$ssl_pem_path" \
		--form "key=@$ssl_key_path" \
		--request POST "$url"
}

update_pages_domain() {
	if [[ "$domain" == "" ]]; then
		echo "[ ERROR ] missing domain. Please specify one."
		exit 1
	fi
	url="${GITLAB_API_URL}/projects/${gitlab_id}/pages/domains/${domain}"

	if [[ ! -f "$ssl_pem_path" || ! -f "$ssl_key_path" ]]; then
		curl --fail \
			--header "PRIVATE-TOKEN: $GITLAB_PRIVATE_TOKEN" \
			--form "domain=$domain" \
			--request PUT "$url"
		exit $?
	fi

	curl --fail \
		--header "PRIVATE-TOKEN: $GITLAB_PRIVATE_TOKEN" \
		--form "domain=$domain" \
		--form "certificate=@$ssl_pem_path" \
		--form "key=@$ssl_key_path" \
		--request PUT "$url"
}

delete_pages_domain() {
	if [[ "$domain" == "" ]]; then
		echo "[ ERROR ] missing domain. Please specify one."
		exit 1
	fi
	url="${GITLAB_API_URL}/projects/${gitlab_id}/pages/domains/${domain}"

	curl --fail \
		--header "PRIVATE-TOKEN: $GITLAB_PRIVATE_TOKEN" \
		--request DELETE "$url"
}


################################
# CLI Parameters and Help      #
################################
print_help() {
	echo "\
GitLab Pages Domains API
API script for managing GitLab Pages Domains. For API specifications, visit:
https://docs.gitlab.com/ee/api/pages_domains.html
-------------------------------------------------------------------------------
To use: $0 [ACTION] [ARGUMENTS]

ENVIRONMENT_VARIABLES
1. export GITLAB_PRIVATE_TOKEN=\"<your account private token>\"
   Compulsory - Your GitLab account private token for API calls.

2. export GITLAB_NAMESPACE=\"<your username / groupname>\"
   Compulsory - Your GitLab username / groupname owning the project.

3. export GITLAB_PROJECT_NAME=\"<your project name>\"
   Compulsory - Your GitLab project name in the URL.


ACTIONS
1. -h, --help			print help.


2. -v, --version		print app version.


3. -l, --list			list pages domains(s).
				COMPULSORY VALUE:
				1. -l all
				  list all pages domains across all projects.

				2. -l project
				  list all pages domains for the specified
				  project.


4. -g, --get			get pages domain.
				COMPULSORY VALUE:
				1. -l <the.domain.name>
				  get the domain values from the given domain
				  name.


5. -c, --create			create the pages domain for the project.
				COMPULSORY VALUE:
				1. -c <the.domain.name>
				  create the domain name for the project pages.

				OPTIONAL ARGUMENTS:
				1. -ssp, --ssl-pem <path/to/ssl.pem>
				  the path to the corresponding ssl pem cert.

				2. -ssk, --ssl-key <path/to/ssl.key>
				  the path to the corresponding ssl key cert.


6. -u, --update			update the pages domain for the project.
				COMPULSORY VALUE:
				1. -u <the.domain.name>
				  create the domain name for the project pages.

				OPTIONAL ARGUMENTS:
				1. -ssp, --ssl-pem <path/to/ssl.pem>
				  the path to the corresponding ssl pem cert.

				2. -ssk, --ssl-key <path/to/ssl.key>
				  the path to the corresponding ssl key cert.


7. -d, --delete			delete the pages domain for the project.
				COMPULSORY VALUE:
				1. -d <the.domain.name>
				  delete the domain name.
"
}

run_action() {
case "$action" in
"la")
	prepare_parameters
	list_all_domains
	;;
"lp")
	prepare_parameters
	list_all_project_pages_domains
	;;
"g")
	prepare_parameters
	get_pages_domain
	;;
"c")
	prepare_parameters
	create_pages_domain
	;;
"u")
	prepare_parameters
	update_pages_domain
	;;
"d")
	prepare_parameters
	delete_pages_domain
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
-l|--list)
	if [[ "$2" != "" && "${2:0:1}" != "-" ]]; then
		case "$2" in
		all)
			action="la"
			;;
		project)
			action="lp"
			;;
		*)
			;;
		esac
		shift 1
	fi
	shift 1
	;;
-g|--get)
	if [[ "$2" != "" && "${2:0:1}" != "-" ]]; then
		domain="$2"
		shift 1
	fi
	action="g"
	shift 1
	;;
-c|--create)
	if [[ "$2" != "" && "${2:0:1}" != "-" ]]; then
		domain="$2"
		shift 1
	fi
	action="c"
	shift 1
	;;
-u|--update)
	if [[ "$2" != "" && "${2:0:1}" != "-" ]]; then
		domain="$2"
		shift 1
	fi
	action="u"
	shift 1
	;;
-d|--delete)
	if [[ "$2" != "" && "${2:0:1}" != "-" ]]; then
		domain="$2"
		shift 1
	fi
	action="d"
	shift 1
	;;
-ssp|--ssl-pem)
	if [[ "$2" != "" && "${2:0:1}" != "-" ]]; then
		ssl_pem_path="$2"
		shift 1
	fi
	shift 1
	;;
-ssk|--ssl-key)
	if [[ "$2" != "" && "${2:0:1}" != "-" ]]; then
		ssl_key_path="$2"
		shift 1
	fi
	shift 1
	;;
-h|--help)
	action="h"
	shift 1
	;;
-v|--version)
	action="v"
	shift 1
	;;
*)
	shift 1
	;;
esac
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
