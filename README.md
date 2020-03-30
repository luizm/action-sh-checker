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
        uses: luizm/action-sh-checker@v0.1.3
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          sh_checker_comment: true
          sh_checker_exclude: ".terraform ^dir/example.sh"
```

### Inputs:

`sh_checker_exclude`: (Optional) Directory or file name that don't need to check.

`sh_checker_shfmt_disable`: (Optional) If true, it will skip the shfmt. Default is false

`sh_checker_shellcheck_disable`: (Optional) If true, it will skip the shellcheck. Default is false

`sh_checker_comment`: (Optional) If true, it will show the errors as commentaries in the pull requests. Default is false

<img width="804" alt="Screen Shot 2020-03-28 at 15 49 58" src="https://user-images.githubusercontent.com/6004689/77831164-3a4ea400-710c-11ea-85ae-778e1df3c469.png">

### Secrets

`GITHUB_TOKEN`: (Optional) The GitHub API token used to post comments to pull requests. Not required if the `sh_checker_comment` input is set to false.
