#!/bin/bash

cd "$GITHUB_WORKSPACE" || exit 1

SHELLCHECK_DISABLE=0
SHFMT_DISABLE=0
SH_CHECKER_COMMENT=0
CHECKBASHISMS_ENABLE=0

if [ "${INPUT_SH_CHECKER_SHELLCHECK_DISABLE}" == "1" ] || [ "${INPUT_SH_CHECKER_SHELLCHECK_DISABLE}" == "true" ]; then
	SHELLCHECK_DISABLE=1
fi

if [ "${INPUT_SH_CHECKER_SHFMT_DISABLE}" == "1" ] || [ "${INPUT_SH_CHECKER_SHFMT_DISABLE}" == "true" ]; then
	SHFMT_DISABLE=1
fi

if [ "${INPUT_SH_CHECKER_COMMENT}" == "1" ] || [ "${INPUT_SH_CHECKER_COMMENT}" == "true" ]; then
	SH_CHECKER_COMMENT=1
fi

if [ "$SHELLCHECK_DISABLE" == "1" ] && [ "$SHFMT_DISABLE" == "1" ]; then
	echo "All checks are disabled, it's mean that \`sh_checker_shellcheck_disable\` and \`sh_checker_shfmt_disable\` are true"
fi

if [ "${INPUT_SH_CHECKER_CHECKBASHISMS_ENABLE}" == "1" ] || [ "${INPUT_SH_CHECKER_CHECKBASHISMS_ENABLE}" == "true" ]; then
	CHECKBASHISMS_ENABLE=1
fi

# Internal functions
_show_sh_files() {
	local sh_files
	sh_files="$(shfmt -f .)"

	if [ -n "$INPUT_SH_CHECKER_EXCLUDE" ]; then
		for i in $INPUT_SH_CHECKER_EXCLUDE; do
			sh_files="$(echo "$sh_files" | grep -Ev "$i")"
		done
	fi

	echo "$sh_files"
}

_comment_on_github() {
	local -r content="
#### \`sh-checker report\`
<details>
<summary>shellcheck output</summary>

\`\`\`
${1:-No errors or shellcheck is disabled}
\`\`\`
</details>

The files above have some shellcheck issues

<details>
<summary>shfmt output</summary>

\`\`\`
${2:-No errors or shfmt is disabled}
\`\`\`
</details>

The files above have some formatting problems, you can use \`shfmt -w\` to fix them

To get the full details about this [job]("https://github.com/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID")

"
	local -r payload=$(echo "$content" | jq -R --slurp '{body: .}')
	local -r comment_url=$(jq -r .pull_request.comments_url <"$GITHUB_EVENT_PATH")

	echo "Commenting on the pull request"
	echo "$payload" | curl -s -S -H "Authorization: token $GITHUB_TOKEN" --header "Content-Type: application/json" --data @- "$comment_url" >/dev/null
}

sh_files="$(_show_sh_files)"

test "$sh_files" || {
	echo "No shell scripts found in this repository. Make a sure that you did a checkout :)"
	exit 0
}

# Validate sh files
shellcheck_code=0
checkbashisms_code=0
shfmt_code=0
exit_code=0

if [ "$SHELLCHECK_DISABLE" != "1" ]; then
	echo -e "Validating shell scripts files using shellcheck\n"
	# shellcheck disable=SC2086
	shellcheck_error=$( (shellcheck $sh_files) | while read -r x; do echo "$x"; done)
	test -n "$shellcheck_error" && {
		shellcheck_code="1"
	}
fi

if [ "$SHFMT_DISABLE" != "1" ]; then
	echo -e "Validating shell scripts files using shfmt\n"
	# shellcheck disable=SC2086
	shfmt_error="$(eval shfmt $SHFMT_OPTS -d $sh_files)"
	shfmt_code="$?"
fi

if [ "$CHECKBASHISMS_ENABLE" == "1" ]; then
	echo -e "Validating 'bashisms' for shell scripts files using checkbashisms\n"
	# shellcheck disable=SC2086
	checkbashisms_error="$(checkbashisms $sh_files)"
	checkbashisms_code="$?"
fi

# Outputs
if [ "$SHELLCHECK_DISABLE" != 1 ]; then
	test "$shellcheck_code" != "0" && {
		echo -e "$shellcheck_error"
		echo -e "\nThe files above have some shellcheck issues\n"
		exit_code=1
	}
fi

if [ "$SHFMT_DISABLE" != 1 ]; then
	test "$shfmt_code" != "0" && {
		echo -e "$shfmt_error"
		echo -e "\nThe files above have some formatting problems, you can use \`shfmt -w\` to fix them\n"
		exit_code=1
	}
fi

if [ "$CHECKBASHISMS_ENABLE" == "1" ]; then
	test "$checkbashisms_code" != "0" && {
		echo -e "$checkbashisms_error"
		echo -e "\nThe files above have some checkbashisms issues\n"
		exit_code=1
	}
fi

if [ "$shellcheck_code" != "0" ] || [ "$shfmt_code" != "0" ]; then
	if [ "$GITHUB_EVENT_NAME" == "pull_request" ] && [ "$SH_CHECKER_COMMENT" == "1" ]; then
		_comment_on_github "$shellcheck_error" "$shfmt_error"
	fi
fi

if [ "$shellcheck_code" == "0" ] && [ "$shfmt_code" == "0" ]; then
	echo -e "All sh files found looks fine :)\n"
fi

exit "$exit_code"
