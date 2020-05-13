#!/bin/bash
GITLAB_API_URL="https://gitlab.com/api/v4"

if [[ -f "${HOME}/.gitlabrc" ]]; then
	. "${HOME}/.gitlabrc"
fi
