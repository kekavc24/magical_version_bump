# 0.5.2

* `feat` : add json support. Just checks file extension for now.

## 0.5.1

* `fix` : tool now keeps custom `build number` by default. Warns the user in console
* `docs` : updated wrong example in README
* `test` : added & updated tests

## 0.5.0

* `feat` : add new `set-version` option to both commands. `yaml-version` will be deprecated in future versions.
* `feat` : add new `preset` flag to `modify` command.
* `feat` : add `keep-pre` & `keep-build` flags to `modify` command.
* `feat` : add `set-build` & `set-prerelease` options to `modify` command.
* `docs` : updated README & examples to be more clear and concise.
* `test` : added new tests for new flags & options.

## 0.4.0

* `feat` : add new `flags` and `options` to `change` command
  * `keep-pre` & `keep-build` flags to nudge the tool to preserve prerelease & build metadata
  * `set-build` & `set-prerelease` options for changing the prerelease & build metadata.

**NOTE** : build & prerelease info will be removed when using the new options.

* `test` : add tests to match new functionality
* `docs` : updated README with new flags & options

## 0.3.0

* `feat` : add `--set-path` flag to both commands. Check README for more info.
* `chore` : update to `Dart 3.0.0`
* `test` : add tests

## 0.2.0

* `refactor` : Default versioning is relative where :
  * incrementing major - defaults minor & patch to zero
  * incrementing minor - defaults only patch to zero

CLI tool will always get the highest relative version based on all flags provided.

* `feat` : add `--absolute` flag for absolute versioning. Each version will be treated as an absolute number.
* `feat` : add new flags/options to `change` command. Check README for more info.
* `docs` : update README and example docs.
* `chore` : improve code readability and testability
* `feat` : add improved tests.

## 0.1.2

* `refactor` : minor perfomance improvements

## 0.1.1

* `chore` : update dependencies
* `chore` : bump dart sdk minimum version to 2.19

## 0.1.0

* `test` : add tests

## 0.0.1-dev.3

* `chore` : remove reference from inspiration project (Local proof of concept).
* `docs` : add dart docs

## 0.0.1-dev.2

* add valid license

## 0.0.1-dev.1

* `chore` : initial package release
* feat: added basic bump/dump for common dart/flutter versioning in pubspec.yaml

**NOTE** : Currently package has no tests yet (working progress). Still works great though. (source: `Dude Trust Me`) ;)
