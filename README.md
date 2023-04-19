# magical_version_bump

<!--![coverage][coverage_badge]-->
[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]

A command-line tool for changing/modifying the version specified in Flutter/Dart pubspec.yaml.

---

## Table of Contents
- [Getting Started](#getting-started)
- [Overview](#overview)
    - [Executable Name](#executable-name)
    - [Available Commands](#commands)
    - [Available Flags](#flags)
- [Usage](#usage)

## Getting Started

```sh
# 🎯 Activate it on your machine

dart pub global activate magical_version_bump
```

## Overview

`magical_version_bump` is a simple command-line tool.

### Executable Name

| Executable Name | Function                    |
|-----------------|-----------------------------|
| `mag`           | Global executable for command-line tool|

### Commands 

| Command  | Function |
|----------|----------|
| `modify` | This command explicitly modifies a specific [SemVer](https://semver.org/) version number in the version specified in your pubspec.yaml.|
| `change` | This command overwrites the version specified in pubspec.yaml file.|

### Flags

All `action` flags precede the `target` flags. Check [examples](/example/README.md) for insight on the same.

| Flags           | Shorthand abbreviation | Type        | Function |
|-----------------|------------------------|-------------|----------|
| `--bump`        | `-b`                   | `action`    | Tells CLI to increment by 1 |
| `--dump`        | `-d`                   | `action`    | Tells CLI to decrement by 1 |
| `--major`       | -                      | `target`    | Tells CLI to target the major version number |
| `--minor`       | -                      | `target`    | Tells CLI to target the minor version number |
| `--patch`       | -                      | `target`    | Tells CLI to target the patch version number |
| `--build-number`| -                      | `target`    | Tells CLI to target the build-number |
| `--with-path`   | -                      | `target`    | Tells CLI to request the path from you and not check the current directory |

## Usage

Usage of the CLI is easy and straight-forward.

```md
# To use it you must include:
$ [executable name] [command] [action flag] [target flag]

# The [action flag] is not required when using the "change" command.
# The target flags can be specified in any order. (They still make grammatical sense) ;)
```

```sh
# Check package version
$ mag -v

# Print help menu
$ mag -h

# Print command help menu
$ mag modify -h

$ mag change -h

```

[Check more examples](/example/README.md).

---

<!--[coverage_badge]: coverage_badge.svg-->
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
[very_good_cli_link]: https://github.com/VeryGoodOpenSource/very_good_cli
