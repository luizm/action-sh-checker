# sh-checker

A GitHub Action that performs static analysis for shell scripts using [shellcheck](https://github.com/koalaman/shellcheck). and [shfmt](https://github.com/mvdan/sh)

## Usage

Job example to check all sh files but ignore the directory `.terraform`

```
name: example
on:
  push:
jobs:
  sh-checker:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v1
      - name: Run the sh-checker
        uses: luizm/action-sh-checker@v0.1.3
        with:
          sh_cheker_comment: true
          sh_checker_shfmt_disable: true # default is false
          sh_cheker_exclude: ".terraform ^path/dirty-dir ^dir/example.sh"
```

### Inputs:

`sh_cheker_comment: (Optional) If true, it will show the errors as commentaries in the pull requests.

`sh_cheker_exclude: (Optional) Directory or file name that don't need to check.

`sh_checker_shfmt_disable: (Optional) If true, it will skip the shfmt. Default is false

`sh_checker_shellcheck_disable: (Optional) If true, it will skip the shellcheck. Default is false
