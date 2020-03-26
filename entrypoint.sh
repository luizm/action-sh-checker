#!/bin/bash

cd "$GITHUB_WORKSPACE" || exit 1

_show_sh_files(){
	local sh_files
	sh_files="$(shfmt -f .)"

	if [ -z "$INPUT_SH_CHECKER_EXCLUDE" ]; then
		for i in $INPUT_SH_CHECKER_EXCLUDE; do
			sh_files="$(echo "$sh_files" | grep -v "$i")"
		done
	fi

	echo "$sh_files"
}

sh_files="$(_show_sh_files)"

if [ -z "$INPUT_SH_CHECKER_SHELLCHECK_DISABLE" ]; then
	echo -e "Validating shell scripts files using shellcheck\n"
	# shellcheck disable=SC2086
	shellcheck $sh_files || {
		echo -e "\nThe files above have some shellcheck issues\n"
		exit_code="1"
	}
fi

if [ -z "$INPUT_SH_CHECKER_SHFMT_DISABLE" ]; then
	echo -e "Validating shell scripts files using shfmt\n"
	# shellcheck disable=SC2086
	shfmt -d $sh_files || {
		echo -e "\nThe files above have some formatting problems, you can use shfmt -w to fix them\n"
		exit_code="1"
	}
fi

if [ -z "$exit_code" ]; then
	echo -e "All sh files found looks fine :)\n"
fi

exit "${exit_code:-0}"
