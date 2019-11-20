#!/bin/bash

cd "$GITHUB_WORKSPACE" || exit 1

echo "Validating shell scripts files using shellcheck:"
shellcheck $(find . -type f -name '*.sh' -not -path \'$EXCLUDE_REGEX\') || exit_code="1"

echo "Validating shell scripts files using shfmt:"
diverging_files="$(shfmt -d $(find . -type f -name '*.sh' -not -path \'$EXCLUDE_REGEX\'))"
if [ -n "$diverging_files" ]; then
  echo "$diverging_files"
	echo -e "The files above have some formatting problems, you can use shfmt -w to fix them:\n"
	exit_code="1"
fi

exit "${exit_code:-0}"
