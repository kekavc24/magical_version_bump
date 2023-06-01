# magical_version_bump

<!--![coverage][coverage_badge]-->
[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]

A command-line tool for changing/modifying the version specified in Flutter/Dart pubspec.yaml.

## Table of Contents
- [Getting Started](#getting-started)
- [Overview](#overview)
    - [Executable Name](#executable-name)
    - [Available Commands](#commands)
    - [Available Flags and Options](#flags-and-options)
- [Default](#default)
- [Basic Usage](#basic-usage)

## Getting Started

```sh
# 🎯 Activate it on your machine

dart pub global activate magical_version_bump
```

## Overview

`magical_version_bump` is a simple command-line tool. Use it to update your yaml files in your project ci/cd. Check out our github action in the repository.

![Update meme](https://storage.googleapis.com/magical_kenya_bucket/7lqtb5.jpg)

## Executable Name

| Executable Name | Function                    |
|-----------------|-----------------------------|
| `mag`           | Global executable for command-line tool|

## Commands 

| Command  | Function |
|----------|----------|
| `modify` | This command explicitly modifies a specific [SemVer](https://semver.org/) version number in the version specified in your pubspec.yaml.|
| `change` | This command overwrites specified node in pubspec.yaml file.|

## Flags and Options

The `modify` command dictates that `action` flags precede the `target` flags. Available flags include: 

| Flags            | Shorthand abbreviation | Type        | Function |
|------------------|------------------------|-------------|----------|
| `--bump`         | `-b`                   | `action`    | Tells CLI to increment by 1 |
| `--dump`         | `-d`                   | `action`    | Tells CLI to decrement by 1 |
| `--major`        | -                      | `target`    | Tells CLI to target the major version number |
| `--minor`        | -                      | `target`    | Tells CLI to target the minor version number |
| `--patch`        | -                      | `target`    | Tells CLI to target the patch version number |
| `--build-number` | -                      | `target`    | Tells CLI to target the build-number |
| `--with-path`    | -                      | `target`    | Tells CLI to request the path from you and not check the current directory |
| `--set-path`     |                        | `N/A`       | Sets path to pubspec.yaml file |

NOTE: `set-path` takes precedence over `with-path`. Tool will remove the `with-path` or any duplicates for this found.

The `change` command takes in options which you can pass in values to. It also includes one flag.

| Flags           | Shorthand abbreviation | Function |
|-----------------|------------------------|----------|
| `--with-path`   | -                      | Tells CLI to request the path from you and not check the current directory |
| `--keep-pre`    | -                      | Explicitly indicates that the tool should keep any existing prerelease version found |
| `--keep-build`  | -                      | Explicitly indicates that the tool should keep any existing build metadata found |

| Options           | Shorthand abbreviation | Function                        |
|-------------------|------------------------|---------------------------------|
| `--set-path`      | -                      | Sets path to pubspec.yaml file |
| `--set-prerelease`  | -                      | Change the prerelease version in the version specified in your pubspec.yaml file |
| `--set-build`     | -                      | Change build metadata appended to the version in your pubspec.yaml file |
| `--name`          | -                      | Change the name in pubspec.yaml |
| `--description`   | -                      | Change the description of your project in pubspec.yaml |
| `--yaml-version`  | -                      | Option to completely change the version in pubspec.yaml |
| `--homepage`      | -                      | Change the homepage url in pubspec.yaml |
| `--repository`    | -                      | Change the repository url for project in pubspec.yaml |
| `--issue_tracker` | -                      | Change the url pointing to an issue tracker in pubspec.yaml |
| `--documentation` | -                      | Change the url pointing to your project's documentation in pubspec.yaml |

## Default
* The tool will always check the current folder for the pubspec.yaml file. Add a `--with-path` flag to nudge the CLI to request the path from you.

```sh
mag modify -b --major --with-path # Requests path

mag modify -b --major --set-path=path-to-fil # Checks directory specified


```

* The tool will always do a relative versioning strategy. The collective version will be bumped up/down based on the position of the version passed in.

```sh
mag modify --bump --major # Bumps version 1.1.1 to 2.0.0

mag modify --bump --minor # Bumps version 1.1.1 to 1.2.0

mag modify --bump --patch # Bumps version 1.1.1 to 1.1.2
```

* The tool allows for various versions to be modified simultaneously. If more than one version target is passed in, version with the highest weight will be used to relatively bump up the collective version.
    * `major` - 20
    * `minor` - 10
    * `patch` - 5
    * `build-number` - 0

```sh
mag modify --bump --major --minor --patch 

# Bumps version 1.1.1 to 2.0.0
# major version has the highest weight

```

* If you need each version to be bumped independently, pass in the `--absolute` flag. 

```sh
mag modify --bump --major --minor --patch --absolute

# Bumps version 1.1.1 to 2.2.2

```

## Basic Usage

Usage of the CLI is easy and straight-forward.

```sh
# Check package version
$ mag -v

# Print help menu
$ mag -h

# Print command help menu
$ mag modify -h

$ mag change -h

```

Check example tab/folder for more.

<!--[coverage_badge]: coverage_badge.svg-->
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
[very_good_cli_link]: https://github.com/VeryGoodOpenSource/very_good_cli
