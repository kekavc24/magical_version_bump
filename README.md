# magical_version_bump

<!--![coverage][coverage_badge]-->
[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]

A command-line tool for changing/modifying the version specified in Flutter/Dart pubspec.yaml.

## Table of Contents
- [Getting Started](#getting-started)
- [Executable Name](#executable-name)
- [Available Commands](#commands)
- [Basic Usage](#basic-usage)
- [Available Flags](#flags)
- [Available Options](#options)
- [Flag & Options in Command](#flags--options-in-commands)
- [Default](#default)
- [Known Caveats](#known-caveats)

## Getting Started

```sh
# 🎯 Activate it on your machine

dart pub global activate magical_version_bump
```

## Overview

`magical_version_bump` is a simple command-line tool. Use it to update your yaml files in your project ci or even locally. Check out our github action in the repository.

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

## Flags

When using the `modify` command, flags are split into 2 categories:
- `action` - specifies whether to `bump` or `dump` the version by 1.
- `target` - specifies which specific [SemVer](https://semver.org/) version number you are targeting.

| Flags            | Shorthand abbreviation | Type        | Function |
|------------------|------------------------|-------------|----------|
| `--bump`         | `-b`                   | `action`    | Tells CLI tool to increment by 1 |
| `--dump`         | `-d`                   | `action`    | Tells CLI tool to decrement by 1 |
| `--major`        | -                      | `target`    | Tells CLI tool to target the major version number |
| `--minor`        | -                      | `target`    | Tells CLI tool to target the minor version number |
| `--patch`        | -                      | `target`    | Tells CLI tool to target the patch version number |
| `--build-number` | -                      | `target`    | Tells CLI tool to target the build-number |
| `--with-path`    | -                      | `target`    | Tells CLI tool to request the path from you and not check the current directory |
| `--preset`       | -                      | N/A         | Explicitly indicates that the tool should preset any version, prerelease and build info before bumping up/down the version |
| `--keep-pre`     | -                      | N/A         | Explicitly indicates that the tool should keep any existing prerelease version found |
| `--keep-build`   | -                      | N/A         | Explicitly indicates that the tool should keep any existing build metadata found |


NOTE: Flags do not take in any value. They are passed in as is.

## Options

These, on the other hand, take in values you explicitly specify. When using options:
- Pass in a value using `=` sign. Like so: `--option=value`
- If the value has any spaces, enclose it with speech marks/double quotes. Like so : `--option="my value with space"`

| Options             | Function                        |
|---------------------|---------------------------------|
| `--set-path`        | Sets path to pubspec.yaml file |
| `--set-prerelease`  | Change the prerelease version in the version specified in your pubspec.yaml file |
| `--set-build`       | Change build metadata appended to the version in your pubspec.yaml file |
| `--set-version`     | Change the version in your pubspec.yaml file |

Other useful options available include:

| Options           | Function                        |
|-------------------|---------------------------------|
| `--name`          | Change the name in pubspec.yaml |
| `--description`   | Change the description of your project in pubspec.yaml |
| `--yaml-version`  | Option to completely change the version in pubspec.yaml |
| `--homepage`      | Change the homepage url in pubspec.yaml |
| `--repository`    | Change the repository url for project in pubspec.yaml |
| `--issue_tracker` | Change the url pointing to an issue tracker in pubspec.yaml |
| `--documentation` | Change the url pointing to your project's documentation in pubspec.yaml |

NOTE: `yaml-version` will be deprecated in favour of `set-version` in future release after `v0.5.0`.

## Flags & Options in Commands

Some flags/options can be used in both command while others cannot. Check table below for more info:

| Flag/Option           | `modify` command  | `change` command  |
| --------------------- | ----------------- | ----------------- |
| `--bump`              |         ✅        |         ❌        |   
| `--dump`              |         ✅        |         ❌        |
| `--major`             |         ✅        |         ❌        |
| `--minor`             |         ✅        |         ❌        |
| `--patch`             |         ✅        |         ❌        |
| `--build-number`      |         ✅        |         ❌        |
| `--with-path`         |         ✅        |         ✅        |
| `--preset`            |         ✅        |         ❌        |
| `--keep-pre`          |         ✅        |         ✅        |
| `--keep-build`        |         ✅        |         ✅        |
| `--set-path`          |         ✅        |         ✅        |
| `--set-prerelease`    |         ✅        |         ✅        |
| `--set-build`         |         ✅        |         ✅        |
| `--set-version`       |         ✅        |         ✅        |
| `--name`              |         ❌        |         ✅        |
| `--description`       |         ❌        |         ✅        |
| `--yaml-version`      |         ❌        |         ✅        |
| `--homepage`          |         ❌        |         ✅        |
| `--repository`        |         ❌        |         ✅        |
| `--issue_tracker`     |         ❌        |         ✅        |
| `--documentation`     |         ❌        |         ✅        |

## Default
* The tool will always check the current folder for the pubspec.yaml file. Add a `--with-path` flag to nudge the CLI to request the path from you.

```sh
mag modify -b --major --with-path # Requests path

mag modify -b --major --set-path=path-to-fil # Checks directory specified

# If set-path is used, with-path will be removed
```

* The tool will always do a relative versioning strategy. The collective version will be bumped up/down based on the position of the version passed in. This is the default versioning recommended by `Dart` & [SemVer](https://semver.org/).

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

* If you pass in `set-version` when using `modify` command, the version will be updated before any other action is performed on the version.

```sh
# Initial version was 2.3.4

mag modify --set-version=8.8.8 --bump major

# Version 2.3.4 updated to 8.8.8 first.
# Version 8.8.8 then bumped to 9.0.0

```

* Using `set-version` also removes the build metadata and any prerelease info in the version. Pass in `--keep-build` or `--keep-pre` to keep desired data
```sh

# Initial version was 2.3.4-alpha+22

mag modify --set-version=8.8.8 --major

# Version will be set to 8.8.8
# Ignores prerelease and build info
# Version 8.8.8 then bumped to 9.0.0


mag modify --set-version=8.8.8 --keep-build --keep-pre

# Version will be set to 8.8.8
# Version 8.8.8 then bumped to 9.0.0
# Ignores prerelease. New versions exit prerelease stage
# Appends build number
# Final version is 9.0.0+22

# Check examples for more tricks

```

## Known Caveats
* Cannot bump prerelease or custom build numbers. To work around this, consider using `set-prerelease` or `set-build`.

If you notice any more issues, please do raise them. Hope you like the package!


<!--[coverage_badge]: coverage_badge.svg-->
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
[very_good_cli_link]: https://github.com/VeryGoodOpenSource/very_good_cli
