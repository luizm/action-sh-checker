#!/bin/bash

cd "$GITHUB_WORKSPACE" || exit 1

SHELLCHECK_DISABLE=0
SHFMT_DISABLE=0
SH_CHECKER_COMMENT=0

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

_comment_on_github(){
	local -r content="
#### \`Shellcheck errors\`
<details><summary>Shellcheck Errors</summary>
\`\`\`
$1
\`\`\`
</details>

The files above have some shellcheck issues

<details><summary>Shftm Errors</summary>
\`\`\`
$2
\`\`\`
</details>

The files above have some formatting problems, you can use shfmt -w to fix them
"
	local -r payload=$(echo "$content" | jq -R --slurp '{body: .}')
	local -r comment_url=$(jq -r .pull_request.comments_url < "$GITHUB_EVENT_PATH")

	echo "Commenting on the pull request"
	echo "$payload" | curl -s -S -H "Authorization: token $GITHUB_TOKEN" --header "Content-Type: application/json" --data @- "$comment_url" > /dev/null
}

sh_files="$(_show_sh_files)"

# Validate sh files
if [ "$SHELLCHECK_DISABLE" != "1" ]; then
	echo -e "Validating shell scripts files using shellcheck\n"
	# shellcheck disable=SC2086
	shellcheck_error="$(shellcheck $sh_files)"
	exit_code="$?"
fi

if [ "$SHFMT_DISABLE" != "1" ]; then
	echo -e "Validating shell scripts files using shfmt\n"
	# shellcheck disable=SC2086
	shfmt_error=$(shfmt -d $sh_files)
	exit_code="$?"
fi

if [ "$exit_code" != 0 ]; then
	echo "$GITHUB_EVENT_NAME"
	echo "$SH_CHECKER_COMMENT"
	if [ "$GITHUB_EVENT_NAME" == "pull_request" ] && [ "$SH_CHECKER_COMMENT" == "1" ]; then
		echo "comment"
		_comment_on_github "$shellcheck_error" "$shfmt_error"
	fi
	test "$SHELLCHECK_DISABLE" != "1" && {
		echo -e "$shellcheck_error"
		echo -e "\nThe files above have some shellcheck issues\n"
	}
	test "$SHFMT_DISABLE" != "1" && {
		echo -e "$shfmt_error"
		echo -e "\nThe files above have some formatting problems, you can use shfmt -w to fix them\n"
	}
	exit 1
else
	echo -e "All sh files found looks fine :)\n"
	exit 0
fi
