#!/bin/bash
################################
# User Variables               #
################################
VERSION="0.1.0"
CERTBOT_CHALLENGE="_acme-challenge"
CERTBOT_DOMAIN="$CERTBOT_DOMAIN"
CERTBOT_VALIDATION="$CERTBOT_VALIDATION"
CLOUDFLARE_EMAIL="$CLOUDFLARE_EMAIL"
CLOUDFLARE_KEY="$CLOUDFLARE_KEY"
DNS_SERVER="$DNS_SERVER"

################################
# App Variables                #
################################
action=""
cloudflare_api="https://api.cloudflare.com/client/v4"
cloudflare_zone=""
retries=180
wait_time=5

################################
# Functions                    #
################################
print_version() {
	echo $VERSION
}

validate_environment_variables() {
	if [[ "$CERTBOT_DOMAIN" == "" ]]; then
		1>&2 echo "[ ERROR ] empty certbot domain."
		exit 1
	fi

	if [[ "$CERTBOT_VALIDATION" == "" ]]; then
		1>&2 echo "[ ERROR ] empty certbot validation value."
		exit 1
	fi

	if [[ "$CLOUDFLARE_EMAIL" == "" ]]; then
		1>&2 echo "[ ERROR ] empty cloudflare auth email."
		exit 1
	fi

	if [[ "$CLOUDFLARE_KEY" == "" ]]; then
		1>&2 echo "[ ERROR ] empty cloudflare auth API key."
		exit 1
	fi
}

get_cloudflare_zone() {
	url="${cloudflare_api}/zones"
	ret="$(curl \
		-H "X-Auth-Email: ${CLOUDFLARE_EMAIL}" \
		-H "X-Auth-Key: ${CLOUDFLARE_KEY}" \
		-s \
		-f \
		-X GET "$url" )"

	domains=($(echo "$ret" | jq -r '.result[].name'))
	i=0
	name=""
	for domain in ${domains[@]}; do
		if [[ "$CERTBOT_DOMAIN" == *"$domain"* ]]; then
			name="$domain"
			break
		fi
		i=$(( i + 1 ))
	done

	if [[ "$name" == "" ]]; then
		echo "[ ERROR ] no suitable cloudflare zone detected."
		exit 1
	fi
	unset name domains

	cloudflare_zone="$(echo "$ret" | jq -r ".result[$i].id")"
	if [[ "$cloudflare_zone" == "" ]]; then
		echo "[ ERROR ] failed to get cloudflare zone"
		exit 1
	fi
}

update_cloudflare_dns() {
	domain="${CERTBOT_CHALLENGE}.${CERTBOT_DOMAIN}"
	url="${cloudflare_api}/zones/${cloudflare_zone}/dns_records"
	data="\
{
	\"type\":\"TXT\",
	\"name\":\"${domain}\",
	\"content\":\"${CERTBOT_VALIDATION}\",
	\"ttl\": 1
}"

	ret="$(curl \
		-H "X-Auth-Email: ${CLOUDFLARE_EMAIL}" \
		-H "X-Auth-Key: ${CLOUDFLARE_KEY}" \
		-H "Content-Type: application/json" \
		-d "$data" \
		-s \
		-f \
		-X POST "$url"
	)"

	verdict="$(echo "$ret" | jq -r ".success")"
	if [[ "$verdict" != "true" ]]; then
		message="$(echo "$ret" | jq -r ".errors[].message")"
		1>&2 echo -e "[ ERROR ] Failed to add record: $message"
		exit 1
	fi

	if [[ "$DNS_SERVER" == "" ]]; then
		DNS_SERVER="8.8.8.8"
	fi

	for ((i=0; i<$retries; i++)); do
		record="$(dig -t TXT ${domain} @${DNS_SERVER} \
			| grep "$CERTBOT_VALIDATION")"
		if [[ "$record" != "" ]]; then
			return 0
		fi
		echo "\
[ INFO ] pending DNS propogation. Sleep ${wait_time}s. $(($retries - $i)) \
rounds left."
		sleep "$wait_time"
	done
	1>&2 echo "[ ERROR ] DNS failed to propogate."
	return 1
}

delete_dns_record() {
	url="${cloudflare_api}/zones/${cloudflare_zone}/dns_records/${1}"

	verdict=$(curl  -H "X-Auth-Email: ${CLOUDFLARE_EMAIL}" \
			-H "X-Auth-Key: ${CLOUDFLARE_KEY}" \
			-H "Content-Type: application/json" \
			-f \
			-s \
			-X DELETE "$url" \
			| jq -r "[.success, .errors[].message] | @csv")

	if [[ "$verdict" != "true" ]]; then
		echo "[ WARNING ] unable to delete ${2}: ${1}"
	fi
}

cleanup_cloudflare_dns() {
	domain="${CERTBOT_CHALLENGE}.${CERTBOT_DOMAIN}"
	url="${cloudflare_api}/zones/${cloudflare_zone}/dns_records"
	url="${url}?type=TXT&name=${domain}"

	ret="$(curl \
		-H "X-Auth-Email: ${CLOUDFLARE_EMAIL}" \
		-H "X-Auth-Key: ${CLOUDFLARE_KEY}" \
		-H "Content-Type: application/json" \
		-s \
		-f \
		-X GET "$url")"

	records=($(echo "$ret" | jq -r ".result[].id"))

	for record in ${records[@]}; do
		delete_dns_record "$record" "$domain"
	done
}

run() {
	validate_environment_variables
	get_cloudflare_zone

	case "$(basename $0)" in
	"update.sh"|"update")
		update_cloudflare_dns
		;;
	"clean.sh"|"clean")
		cleanup_cloudflare_dns
		;;
	*)
		;;
	esac
}

################################
# CLI Parameters and Help      #
################################
print_help() {
	echo "\
Cloudflare Update DNS API
The single script that updates Cloudflare DNS API using curl and jq commands.
-------------------------------------------------------------------------------
To use: $0 [ACTION] [ARGUMENTS]

ACTIONS
1. -h, --help			print help. Longest help is up
				to this length for terminal
				friendly printout.

2. -r, --run			run the program. In this case, run based on
				program name. Rename this script to:
				1) update.sh, update
				   to create CERTBOT TXT challenge DNS record.
				2) clean.sh, clean
				   to delete CERTBOT TXT challenge DNS record.

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
*)
	run
	;;
esac
}

process_parameters() {
while [[ $# != 0 ]]; do
case "$1" in
-r|--run)
	action="r"
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
	if [[ $? != 0 ]]; then
		exit 1
	fi

	run_action
	if [[ $? != 0 ]]; then
		exit 1
	fi
}

if [[ $BASHELL_TEST_ENVIRONMENT != true ]]; then
	main $@
fi
