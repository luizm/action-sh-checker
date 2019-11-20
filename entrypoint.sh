#!/bin/bash

cd "$GITHUB_WORKSPACE" || exit 1

echo -e "Validating shell scripts files using shellcheck\n"
shellcheck $(find . -type f -name '*.sh' -not -regex "$SH_CHECKER_EXCLUDE_REGEX") || {
	echo -e "\nThe files above have some shellcheck issues\n"
	exit_code="1"
}

echo -e "Validating shell scripts files using shfmt\n"
diverging_files="$(shfmt -d $(find . -type f -name '*.sh' -not -regex "$SH_CHECKER_EXCLUDE_REGEX"))"
if [ -n "$diverging_files" ]; then
  echo "$diverging_files"
	echo -e "\nThe files above have some formatting problems, you can use shfmt -w to fix them\n"
	exit_code="1"
fi

if [ -z "$exit_code" ]; then
	echo -e "All sh files found looks fine :)\n"
fi

exit "${exit_code:-0}"
