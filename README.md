# magical_version_bump

[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]

A command-line tool for changing/modifying the version specified in Flutter/Dart pubspec.yaml. Use it to also modify other nodes in your yaml file.

## Table of Contents

- [Getting Started](#getting-started)
- [Executable Name](#executable-name)
- [Basic Usage](#basic-usage)
- [Available Commands](#available-commands)
- [Default](#default)
- [Known Caveats](#known-caveats)

## Getting Started

```sh
# 🎯 Activate it on your machine

dart pub global activate magical_version_bump
```

## Overview

`magical_version_bump` is a simple command-line tool. Use it to automate how you update your yaml/json files.

A github workflow and a variety of actions using this package is available at `magical_workflows`.  [Checkout repo ✨][workflow_repo_link]

![Update meme](https://storage.googleapis.com/magical_kenya_bucket/7lqtb5.jpg)

## Executable Name

The global executable name activated by `Dart` is `mag`.

## Basic Usage

Usage of the CLI is easy and straight-forward.

```bash
# Check package version
$ mag -v

# Print help menu
$ mag -h

# Print command help menu
$ mag <command> -h

```

Check example folder for more info.

## Available Commands

### Modify command

This command manipulates the contents of an existing yaml/json file.

Available subcommands include :

- `set` - overwrites/appends to nodes in your yaml/json files. Read more <a href="./example/SET_COMMAND.md" target = "blank">here</a>
- `bump` - bumps the version in your yaml/json file. Read more <a href="./example/BUMP_COMMAND.md" target = "blank">here</a>

## Default

- The tool will always check the current folder for the pubspec.yaml file. Add a `--request-path` flag to nudge the CLI to request the path from you. Use `directory` to point it to file.

```bash

mag modify bump --targets "major" --request-path
# Will request path from you in an interactive way in the console

mag modify bump --targets "major" --directory="my-path/pubspec.yaml" 
# Automatically checks directory specified

```

- The tool will always do a relative versioning strategy. The collective version will be bumped up/down based on the position of the version passed in. This is the default versioning recommended by `Dart` & [SemVer](https://semver.org/).

```sh
mag modify bump --targets "major" # Bumps version 1.1.1 to 2.0.0

mag modify bump --targets 'minor' # Bumps version 1.1.1 to 1.2.0

mag modify bump --targets 'patch' # Bumps version 1.1.1 to 1.1.2
```

- The tool allows for various versions to be modified simultaneously. If more than one version target is passed in, version with the highest weight will be used to relatively bump up the collective version.
  - `major` - 20
  - `minor` - 10
  - `patch` - 5
  - `build-number` - 0

```bash
mag modify bump --targets "major,minor,patch"

# Bumps version 1.1.1 to 2.0.0
# major version has the highest weight

```

- If you need each version to be bumped independently, just pass in the `--absolute` flag.

```bash
mag modify bump --targets "major,minor,patch" --strategy "absolute"

# Bumps version 1.1.1 to 2.2.2

```

## Known Caveats

This tool cannot bump custom prerelease or build numbers. Consider using `set-prerelease` or `set-build` as a work around. However, if you would like this implemented, create a feature request in the repo 👍🏼.

If you notice any more issues, please do raise them. Hope you like the package!

All code contributions and reviews are welcome ❤.

[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
[workflow_repo_link]: https://github.com/kekavc24/magical_workflows
