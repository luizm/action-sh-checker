# sh-checker

A GitHub Action that performs static analysis for shell scripts using [shellcheck](https://github.com/koalaman/shellcheck) and [shfmt](https://github.com/mvdan/sh)

## Usage

Job example to check all sh files but ignore the directory `.terraform` and file `dir/example.sh`

```
name: example
on:
  - pull_request
jobs:
  sh-checker:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v1
      - name: Run the sh-checker
        uses: luizm/action-sh-checker@v0.1.4
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          SHELLCHECK_OPTS: -e SC1004 # It is posible to exclude some shellcheck warnings.
          SHFMT_OPTS: -s # It is posible to pass arguments to shftm
        with:
          sh_checker_comment: true
          sh_checker_exclude: ".terraform ^dir/example.sh"
```

![Screen Shot 2020-04-01 at 12 18 59](https://user-images.githubusercontent.com/6004689/78155536-f9a8a080-7413-11ea-8b5c-2c96484feb61.png)

### Environment Variables 

`SHELLCHECK_OPTS`: Used to specify a shellcheck arguments

`SHFMT_OPTS`: Used to specify a shfmt argments

### Inputs

`sh_checker_exclude`: (Optional) Directory or file name that doesn't need to be checked.

`sh_checker_shfmt_disable`: (Optional) If true, it will skip the shfmt. Default is false

`sh_checker_shellcheck_disable`: (Optional) If true, it will skip the shellcheck. Default is false

`sh_checker_comment`: (Optional) If true, it will show the errors as commentaries in the pull requests. Default is false

### Secrets

`GITHUB_TOKEN`: (Optional) The GitHub API token used to post comments to pull requests. Not required if the `sh_checker_comment` input is set to false.
