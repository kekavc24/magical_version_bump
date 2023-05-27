# 0.0.1-dev.1

* Initial package release
* feat: added basic bump/dump for common dart/flutter versioning in pubspec.yaml
* Currently package has no tests yet (working progress). Still works great though. (source: Dude Trust Me) ;)

# 0.0.1-dev.2

* Added valid license

# 0.0.1-dev.3

* Removed reference from inspiration project.
* Added dart docs

# 0.1.0

* Added tests

# 0.1.1

* Routine pub upgrade
* Bump up dart sdk minimum version to 2.19

# 0.1.2

* Minor improvements.

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
* Fixed lurking bugs.
* Improved code readability and testability
* Added improved tests.

# 0.3.0
**Features**
* Added `--set-path` flag to both commands. Check README for more info.

**Fixes & Improvements**
* Update to Dart 3
* Fixed lurking bugs
* Improved tests
