# 0.5.1
**Fixes**
* tool now keeps custom `build number` by default. Warns the user in console

**Improvements**
* updated wrong example in README
* added & updated tests

# 0.5.0
**Features**
* added new `set-version` option to both commands. `yaml-version` will be deprecated in future versions.
* added new `preset` flag to `modify` command.
* added `keep-pre` & `keep-build` flags to `modify` command.
* added `set-build` & `set-prerelease` options to `modify` command.

Check README & example for more info.

**Improvements**
* updated README & examples to be more clear and concise.
* added new tests for new flags & options.

# 0.4.0
**Features**
* added new `flags` and `options` to `change` command
    * `keep-pre` & `keep-build` flags to nudge the tool to preserve prerelease & build metadata
    * `set-build` & `set-prerelease` options for changing the prerelease & build metadata
* build & prerelease info will be removed when using the new options.

**Improvements**
* updated changelog readability to show latest versions first
* added tests to match new functionality
* updated README with new flags & options

# 0.3.0

**Features**
* add `--set-path` flag to both commands. Check README for more info.

**Improvements**
* update to `Dart 3.0.0`
* improve tests

# 0.2.0

**Minor Changes**
* Default versioning is relative where :
    * incrementing major - defaults minor & patch to zero
    * incrementing minor - defaults only patch to zero
* CLI tool will always get the highest relative version based on all flags provided.

**Features**
* Added `--absolute` flag for absolute versioning. Each version will be treated as an absolute number.
* Added new flags/options to `change` command. Check README for more info.

**Fixes & Improvements**
* Updated README and example docs.
* Improved code readability and testability
* Added improved tests.

# 0.1.2

* Minor improvements.

# 0.1.1

* Routine pub upgrade
* Bump up dart sdk minimum version to 2.19

# 0.1.0

* Added tests

# 0.0.1-dev.3

* Removed reference from inspiration project.
* Added dart docs

# 0.0.1-dev.2

* Added valid license

# 0.0.1-dev.1

* Initial package release
* feat: added basic bump/dump for common dart/flutter versioning in pubspec.yaml
* Currently package has no tests yet (working progress). Still works great though. (source: Dude Trust Me) ;)