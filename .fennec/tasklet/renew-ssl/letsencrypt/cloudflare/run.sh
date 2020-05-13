#!/bin/bash
################################
# User Variables               #
################################
VERSION="1.0.0"
INSTALLER="${INSTALLER:-""}"
PAGE_DOMAINS="${PAGE_DOMAINS:-""}"
CLOUDFLARE_EMAIL="${CLOUDFLARE_EMAIL:-""}"
CLOUDFLARE_KEY="${CLOUDFLARE_KEY:-""}"
SSL_EMAIL="${SSL_EMAIL:-""}"
GITLAB_PRIVATE_TOKEN="${GITLAB_PRIVATE_TOKEN:-""}"

################################
# App Variables                #
################################
action=""
sudoer=""
dependencies=(
	"curl"
	"bash"
	"certbot"
	"jq"
	"dnsutils"
	"gpg"
)
current_path="$PWD"
certbot_auto="certbot_auto"
gitlab_api="https://gitlab.com/api/v4/projects"
ssl_work_path="${current_path}/tmp"
ssl_pem_path=""
ssl_key_path=""
ssl_cmd_path="${current_path}/bin"
certbot_path="${ssl_cmd_path}/${certbot_auto}"
dns_hook_path="${current_path}/\
fennec/tasklet/renew-ssl/letsencrypt/cloudflare/dns.sh"
cloudflare_update_hook="${ssl_cmd_path}/update.sh"
cloudflare_clean_hook="${ssl_cmd_path}/clean.sh"

################################
# Functions                    #
################################
_print_status() {
	status_mode="$1" && shift 1

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

	1>&2 echo "$status_message"
}

print_version() {
	echo $VERSION
}

_verify_variables() {
	if [ "$GITLAB_PRIVATE_TOKEN" = "" ]; then
		_print_status error "missing GITLAB_PRIVATE_TOKEN."
		exit 1
	fi

	if [ "$SSL_EMAIL" = "" ]; then
		_print_status error "missing SSL_EMAIL notification email."
		exit 1
	fi

	if [ "$CLOUDFLARE_EMAIL" = "" ]; then
		_print_status error "missing CLOUDFLARE_EMAIL api login."
		exit 1
	fi

	if [ "$CLOUDFLARE_KEY" = "" ]; then
		_print_status error "missing CLOUDFLARE_KEY api login."
		exit 1
	fi

	if [ "$PAGE_DOMAINS" = "" ]; then
		_print_status error "missing PAGE_DOMAINS."
		exit 1
	fi
}

_identify_installer() {
	if [ ! "$INSTALLER" = "" ]; then
		return 0
	fi

	if [ ! "$(which apt-get)" = "" ]; then
		export INSTALLER="apt-get"
		return 0
	fi

	if [ ! "$(which yum)" = "" ]; then
		export INSTALLER="yum"
		return 0
	fi

	_print_status error "unknown package manager."
	exit 1
}

_request_root_access() {
	if [ "$USER" = "root" ]; then
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

	_print_status error "problem with root access."
	exit 1
}

_install_dependency() {
	if [ "$sudoer" = "" ]; then
		_installer_command="$INSTALLER"
	else
		_installer_command="sudo $INSTALLER"
	fi

	for item in "${dependencies[@]}"; do
		"$_installer_command" install "$item"
	done
}

_setup_ssl() {
	# prepare
	mkdir -p "$ssl_cmd_path"
	certbot_auto_path="${PWD}/${certbot_auto}"
	certbot_gpg_path="${PWD}/${certbot_auto}.asc"

	# download
	curl --silent --fail --remote-name https://dl.eff.org/certbot-auto
	if [ ! -f "$certbot_auto_path" ]; then
		_print_status error "failed to download certbot-auto."
		exit 1
	fi

	curl --silent --fail --remote-name https://dl.eff.org/certbot-auto.asc
	if [ ! -f "$certbot_gpg_path" ]; then
		_print_status error "failed to download certbot-auto asc file."
		exit 1
	fi

	# verify
	gpg --recv-key A2CFB51FA275A7286234E7B24D17C995CD9775F2
	gpg --trusted-key 4D17C995CD9775F2 \
		--verify "$certbot_gpg_path" "$certbot_auto_path"
	rm "$certbot_gpg_path" && unset certbot_gpg_path

	# setup
	chmod a+x "$certbot_auto_path"
	mv "$certbot_auto_path" "$certbot_path" && unset certbot_auto_path
	cp "$dns_hook_path" "$cloudflare_update_hook"
	chmod a+x "$cloudflare_update_hook"
	cp "$dns_hook_path" "$cloudflare_clean_hook"
	chmod a+x "$cloudflare_clean_hook"
}

_execute_renewal() {
	private_token="PRIVATE-TOKEN: \"$GITLAB_PRIVATE_TOKEN\""
	domains=(${PAGE_DOMAINS/,/ })

	for domain in "${domains[@]}"; do
		rm -rf "$ssl_work_path" > /dev/null
		mkdir -p "$ssl_work_path"
		"$certbot_path" certonly \
			--text \
			--agree-tos \
			--email "$SSL_EMAIL" \
			--manual \
			--manual-public-ip-logging-ok \
			--manual-auth-hook "$cloudflare_update_hook" \
			--manual-clean-hook "$cloudflare_clean_hook" \
			--preferred-challenges dns \
			--config-dir "$ssl_work_path" \
			--non-interactive \
			--domain "$domain"
		export ssl_pem_path="\
${ssl_work_path}/live/${domain}/fullchain.pem"
		export ssl_key_path="\
${ssl_work_path}/live/${domain}/privkey.pem"
		if [ ! -f "$ssl_pem_path" ] || [ ! -f "$ssl_key_path" ]; then
			_print_status error "no ssl cert/key for $domain"
			continue
		fi
		export gitlab_namespace="$CI_PROJECT_NAMESPACE"
		export gitlab_project_name="$CI_PROJECT_NAME"
		./.fennec/api/gitlab/pages_domains.sh \
			--update "$domain" \
			--ssl-pem "$ssl_pem_path" \
			--ssl-key "$ssl_key_path"
	done
}

run() {
	_verify_variables
	_identify_installer
	_request_root_access
	_install_dependency
	_setup_ssl
	_execute_renewal
}

################################
# CLI Parameters and Help      #
################################
print_help() {
	echo "\
Cloudflare LetsEncrypt Renewal Script
One script that renews the LetsEncrypt SSL easily
-------------------------------------------------------------------------------
To use: $0 [ACTION] [ARGUMENTS]

ACTIONS
1. -h, --help			print help. Longest help is up
				to this length for terminal
				friendly printout.

2. -r, --run			run the program. In this case,
				says the message.

3. -v, --version		print app version.
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
	return 1
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
