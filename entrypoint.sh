#!/usr/bin/env bash

cd "$GITHUB_WORKSPACE" || {
	printf 'Directory not found: "%s"\n' "$GITHUB_WORKSPACE"
	exit 1
}

SHELLCHECK_DISABLE=0
SHFMT_DISABLE=0
SH_CHECKER_COMMENT=0
CHECKBASHISMS_ENABLE=0
SH_CHECKER_ONLY_DIFF=0

shopt -s nocasematch

if [[ "${INPUT_SH_CHECKER_SHELLCHECK_DISABLE}" =~ ^(1|true|on|yes)$ ]]; then
	SHELLCHECK_DISABLE=1
fi

if [[ "${INPUT_SH_CHECKER_SHFMT_DISABLE}" =~ ^(1|true|on|yes)$ ]]; then
	SHFMT_DISABLE=1
fi

if [[ "${INPUT_SH_CHECKER_COMMENT}" =~ ^(1|true|on|yes)$ ]]; then
	SH_CHECKER_COMMENT=1
fi

if [[ "${INPUT_SH_CHECKER_CHECKBASHISMS_ENABLE}" =~ ^(1|true|on|yes)$ ]]; then
	CHECKBASHISMS_ENABLE=1
fi

if [[ "${INPUT_SH_CHECKER_ONLY_DIFF}" =~ ^(1|true|on|yes)$ ]]; then
	SH_CHECKER_ONLY_DIFF=1
fi

if ((SHELLCHECK_DISABLE == 1 && SHFMT_DISABLE == 1 && CHECKBASHISMS_ENABLE != 1)); then
	echo "All checks are disabled: \`sh_checker_shellcheck_disable\` and \`sh_checker_shfmt_disable\` are both set to 1/true."
fi

# Internal functions
_show_sh_files() {
	# Store the array of files to check in sh_files
	# using a global, as returning arrays in bash is ugly
	# setting IFS to \n allows for spaces in file names:
	if ((SH_CHECKER_ONLY_DIFF == 1)); then
		# Compute the intersection of all shell scripts in the repo and files changes on the PR branch
		if [[ "$GITHUB_REF" =~ ^refs/pull/ ]]; then
			# The `on: pull_request` trigger does not give branch information, so we need to supply the PR number to gh
			# See https://frontside.com/blog/2020-05-26-github-actions-pull_request/
			# and https://docs.github.com/en/actions/learn-github-actions/variables
			pr_number="$(echo "$GITHUB_REF" | cut -d/ -f3)"
		else
			pr_number="" # have gh figure out the PR number from the branch name
		fi
		IFS=$'\n' mapfile -t sh_files < <(sort <(shfmt -f .) <(gh pr diff "$pr_number" --name-only) | uniq -d)
		echo "Checking only the shell script(s) changed in the PR branch:"
		printf '"%s"\n' "${sh_files[@]}"
	else
		IFS=$'\n' mapfile -t sh_files < <(shfmt -f .)
	fi

	if [ -z "$INPUT_SH_CHECKER_EXCLUDE" ]; then
		return 0
	fi

	OLDIFS="$IFS"
	IFS=$' \t\n' read -d '' -ra excludes <<<"$INPUT_SH_CHECKER_EXCLUDE"
	IFS=$'\n'
	sh_all=("${sh_files[@]}")
	sh_files=()
	excluded=()
	local sh exclude
	for sh in "${sh_all[@]}"; do
		for exclude in "${excludes[@]}"; do
			grep -q -E "$exclude" <<<"$sh" || continue
			excluded+=("$sh")
			continue 2
		done
		sh_files+=("$sh")
	done
	if (("${#excluded[@]}" != 0)); then
		printf 'The following %d shell script(s) will not be checked:\n' "${#excluded[@]}"
		printf '"%s"\n' "${excluded[@]}"
	fi
	IFS="$OLDIFS"
}

_comment_on_github() {
	local content
	IFS= read -r -d '' content <<EOF
#### \`sh-checker report\`

To get the full details, please check in the [job]("https://github.com/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID") output.

<details>
<summary>shellcheck errors</summary>

\`\`\`
$1
\`\`\`
</details>

<details>
<summary>shfmt errors</summary>

\`\`\`
$2
\`\`\`
</details>

EOF
	local -r payload=$(jq -R --slurp '{body: .}' <<<"$content")
	local -r comment_url=$(jq -r .pull_request.comments_url <"$GITHUB_EVENT_PATH")

	echo "Commenting on the pull request"
	curl -s -S -H "Authorization: token $GITHUB_TOKEN" --header "Content-Type: application/json" --data @- "$comment_url" <<<"$payload"
}

_show_sh_files

((${#sh_files[@]} == 0)) && {
	if ((SH_CHECKER_ONLY_DIFF == 1)); then
		echo "No shell scripts were changed."
		exit 0
	fi
	if [ -n "$INPUT_SH_CHECKER_EXCLUDE" ]; then
		if ((${#excluded[@]} == ${#sh_all[@]})); then
			printf 'All %d shell script(s) have been excluded per your sh_checker_exclude setting:\n' "${#sh_all[@]}"
			IFS=$' \t\n' printf '"%s"\n' "${excludes[@]}"
			exit 0
		fi
	fi
	echo "No shell scripts were found in this repository. Please check your settings."
	exit 0
}

# Validate sh files
shellcheck_code=0
checkbashisms_code=0
shfmt_code=0
exit_code=0
shellcheck_error='shellcheck checking is disabled.'
shfmt_error='shfmt checking is disabled.'

if ((SHELLCHECK_DISABLE != 1)); then
	printf "Validating %d shell script(s) using 'shellcheck %s':\\n" "${#sh_files[@]}" "$SHELLCHECK_OPTS"
	IFS=$' \t\n' read -d '' -ra args <<<"$SHELLCHECK_OPTS"
	shellcheck_output="$(shellcheck "${args[@]}" "${sh_files[@]}" 2>&1)"
	shellcheck_code=$?
	if ((shellcheck_code == 0)); then
		printf -v shellcheck_error "'shellcheck %s' found no issues.\\n" "$SHELLCHECK_OPTS"
	else
		# .shellcheck returns 0-4: https://github.com/koalaman/shellcheck/blob/dff8f9492a153b4ad8ac7d085136ce532e8ea081/shellcheck.hs#L191
		exit_code=$shellcheck_code
		IFS= read -r -d '' shellcheck_error <<EOF

'shellcheck $SHELLCHECK_OPTS' returned error $shellcheck_code finding the following syntactical issues:

----------
$shellcheck_output
----------

You can address the above issues in one of three ways:
1. Manually correct the issue in the offending shell script;
2. Disable specific issues by adding the comment:
  # shellcheck disable=NNNN
above the line that contains the issue, where NNNN is the error code;
3. Add '-e NNNN' to the SHELLCHECK_OPTS setting in your .yml action file.


EOF
	fi
	printf '%s' "$shellcheck_error"
fi

if ((SHFMT_DISABLE != 1)); then
	printf "Validating %d shell script(s) using 'shfmt %s':\\n" "${#sh_files[@]}" "$SHFMT_OPTS"
	IFS=$' \t\n' read -d '' -ra args <<<"$SHFMT_OPTS"
	# Error with a diff when the formatting differs
	args+=('-d')
	# Disable colorization of diff output
	export NO_COLOR=1
	shfmt_output="$(shfmt "${args[@]}" "${sh_files[@]}" 2>&1)"
	shfmt_code=$?
	if ((shfmt_code == 0)); then
		printf -v shfmt_error "'shfmt %s' found no issues.\\n" "$SHFMT_OPTS"
	else
		# shfmt returns 0 or 1: https://github.com/mvdan/sh/blob/dbbad59b44d586c0f3d044a3820c18c41b495e2a/cmd/shfmt/main.go#L72
		((exit_code |= 8))
		IFS= read -r -d '' shfmt_error <<EOF

'shfmt $SHFMT_OPTS' returned error $shfmt_code finding the following formatting issues:

----------
$shfmt_output
----------

You can reformat the above files to meet shfmt's requirements by typing:

  shfmt $SHFMT_OPTS -w filename

EOF
	fi
	printf '%s' "$shfmt_error"
fi

if ((CHECKBASHISMS_ENABLE == 1)); then
	printf '\n\nValidating %d shell script(s) files using checkbashisms:\n' "${#sh_files[@]}"
	checkbashisms "${sh_files[@]}"
	checkbashisms_code=$?
	if ((checkbashisms_code == 0)); then
		printf '\ncheckbashisms found no issues.\n'
	else
		printf '\ncheckbashisms returned error %d finding the bashisms listed above.\n' "$checkbashisms_code"
		if ((checkbashisms_code == 4)); then
			# see https://github.com/duggan/shlint/blob/0fcd979319e3f37c2cd53ccea0b51e16fda710a1/lib/checkbashisms#L489
			printf "\\nIgnoring the spurious non-issue titled 'could not find any possible bashisms in bash script'\\n"
		else
			# checkbashisms returns 0-3: https://linux.die.net/man/1/checkbashisms
			((exit_code |= (checkbashisms_code << 4)))
		fi
	fi
fi

if ((shellcheck_code != 0 || shfmt_code != 0)); then
	if [ "$GITHUB_EVENT_NAME" == "pull_request" ] && ((SH_CHECKER_COMMENT == 1)); then
		_comment_on_github "$shellcheck_error" "$shfmt_error"
	fi
fi

if ((exit_code == 0)); then
	printf '\nNo issues found in the %d shell script(s) scanned :)\n' "${#sh_files[@]}"
fi

# shellcheck disable=SC2086
exit $exit_code
