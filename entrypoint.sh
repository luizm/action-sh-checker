#!/bin/bash

RED="$(tput setaf 1)"
GREEN="$(tput setaf 2)"
RESET="$(tput sgr0)"

cd "$GITHUB_WORKSPACE" || exit 1

echo -e "Validating shell scripts files using shellcheck:\n"
shellcheck $(find . -type f -name '*.sh' | grep -Ev \"$EXCLUDE_REGEX\") || {
	echo -e "\n$RED The files above have some shellcheck issues\n $RESET"
	exit_code="1"
}

echo -e "Validating shell scripts files using shfmt:\n"
diverging_files="$(shfmt -d $(find . -type f -name '*.sh' | grep -Ev \"$EXCLUDE_REGEX\"))"
if [ -n "$diverging_files" ]; then
  echo "$diverging_files"
	echo -e "\n$RED The files above have some formatting problems, you can use shfmt -w to fix them\n $RESET"
	exit_code="1"
fi

if [ -z "$exit_code" ]; then
	echo -e "\n$GREEN All sh files found looks fine :) $RESET\n"
fi

exit "${exit_code:-0}"
