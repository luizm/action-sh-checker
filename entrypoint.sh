#!/bin/bash

cd "$GITHUB_WORKSPACE" || exit 1

shellcheck $(find . -type f -name '*.sh' -not -path '*/.terraform/*') || exit_code="1"

diverging_files="$(shfmt -d $(find . -type f -name '*.sh'))"
if [ -n "$diverging_files" ]; then
  echo "$diverging_files"
	echo -e "The files above have some formatting problems, you can use shfmt -w to fix them:\n"
	exit_code="1"
fi

exit "${exit_code:-0}"
