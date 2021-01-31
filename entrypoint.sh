#!/usr/bin/env bash

cd "$GITHUB_WORKSPACE" || {
  printf 'Directory not found: "%s"\n' "$GITHUB_WORKSPACE"
  exit 1
}

SHELLCHECK_DISABLE=0
SHFMT_DISABLE=0
SH_CHECKER_COMMENT=0
CHECKBASHISMS_ENABLE=0

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

if ((SHELLCHECK_DISABLE == 1 && SHFMT_DISABLE == 1 && CHECKBASHISMS_ENABLE != 1)); then
  echo "All checks are disabled: \`sh_checker_shellcheck_disable\` and \`sh_checker_shfmt_disable\` are both set to 1/true."
fi

# Internal functions
_show_sh_files() {
  # using a global, as returning arrays in bash is ugly
  # setting IFS to \n allows for spaces in file names:
  IFS=$'\n' mapfile -t sh_files < <(shfmt -f .)

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
  read -r -d '' content <<EOF
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
  curl -s -S -H "Authorization: token $GITHUB_TOKEN" --header "Content-Type: application/json" --data @- "$comment_url" <<<"$payload" >/dev/null
}

_show_sh_files

((${#sh_files[@]} == 0)) && {
  if ((ONLY_DIFF == 1)); then
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
  shellcheck_error="$(shellcheck "${args[@]}" "${sh_files[@]}" 2>&1)"
  shellcheck_code=$?
  if ((shellcheck_code == 0)); then
    printf "'shellcheck %s' found no issues.\\n" "$SHELLCHECK_OPTS"
  else
    # .shellcheck returns 0-4: https://github.com/koalaman/shellcheck/blob/dff8f9492a153b4ad8ac7d085136ce532e8ea081/shellcheck.hs#L191
    exit_code=$shellcheck_code
    printf "\\n'shellcheck %s' returned error %s finding the following syntactical issues:\\n" "$SHELLCHECK_OPTS" "$shellcheck_code"
    printf '%s' "$shellcheck_error"
    printf '\n'
    printf 'You can address these issues in three ways:\n'
    printf '1. Manually correct the issue in the offending shell script;\n'
    printf '2. Disable specific issues by adding the comment:\n'
    printf '  # shellcheck disable=NNNN\n'
    printf 'above the line that contains the issue, where NNNN is the error code;\n'
    printf "3. Add '-e NNNN' to the SHELLCHECK_OPTS setting in your .yml action file.\\n"
  fi
fi

if ((SHFMT_DISABLE != 1)); then
  printf "Validating %d shell script(s) using 'shfmt %s':\\n" "${#sh_files[@]}" "$SHFMT_OPTS"
  IFS=$' \t\n' read -d '' -ra args <<<"$SHFMT_OPTS"
  shfmt_error="$(shfmt "${args[@]}" "${sh_files[@]}" 2>&1)"
  shfmt_code=$?
  if ((shfmt_code == 0)); then
    printf "'shfmt %s' found no issues.\\n" "$SHFMT_OPTS"
  else
    # shfmt returns 0 or 1: https://github.com/mvdan/sh/blob/dbbad59b44d586c0f3d044a3820c18c41b495e2a/cmd/shfmt/main.go#L72
    ((exit_code |= 8))
    printf "\\n'shfmt %s' returned error %d finding the following formatting issues:\\n" "$SHFMT_OPTS" "$shfmt_code" 
    printf '%s' "$shfmt_error"
    printf '\n'
    printf "You can use 'shfmt %s -w filename' to reformat each filename to meet shfmt's requirements.\\n" "$SHFMT_OPTS"
  fi
fi

if ((CHECKBASHISMS_ENABLE == 1)); then
  printf 'Validating %d shell script(s) files using checkbashisms:\n' "${#sh_files[@]}"
  checkbashisms "${sh_files[@]}"
  checkbashisms_code=$?
  if ((checkbashisms_code == 0)); then
    printf 'checkbashisms found no issues.\n'
  else
    printf '\ncheckbashisms returned error %d finding the bashisms listed above.\n' "$checkbashisms_code"
    if ((checkbashisms_code == 4)); then
      # see https://github.com/duggan/shlint/blob/0fcd979319e3f37c2cd53ccea0b51e16fda710a1/lib/checkbashisms#L489
      printf "Ignoring 'could not find any possible bashisms in bash script' issues\\n"
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
  printf 'No issues found in the %d shell script(s) scanned :)\n' "${#sh_files[@]}"
fi

exit $exit_code
