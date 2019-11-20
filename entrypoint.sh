#!/bin/bash

cd "$GITHUB_WORKSPACE" || exit 1
find . -type f -name \*.sh -exec shellcheck {} +

bash -c "shfmt --version"

diverging_files="$(shfmt -d $(find . -type f -name '*.sh'))"
if [ -n "$diverging_files" ]; then
  echo "$diverging_files"
	echo -e "The files above have some formatting problems, you can use shfmt -w to fix them:\n"
	exit 1
fi
