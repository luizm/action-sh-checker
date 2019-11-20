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
      - name: run the sh-checker
        uses: luizm/action-sh-checker@v0.1.2
        with:
          exclude-regex: "*/.terraform/*"
```

**Optional inputs**
- exclude-regex