# Preface

Consider this sentence, `I want you to update my computer`.

If we were to analyze it, it is subjective to say that there is an action and a target in the sentence.

``` md
update - ACTION

my computer - TARGET
```

Thus, by using this CLI tool, you are portrayed in the sentence below:

`I want you to modify, by bumping up/down, my pubspec.yaml's major/minor/patch/build-number version` where :

``` md
modify, by bumping up/down - ACTION

my pubspec.yaml's major/minor/patch/build-number version - TARGET

```

## Basic Usage

By default, the command will update any `pubspec.yaml` file in the current directory and bumps up each version relative to its position.

* Bump up any version by 1. You have to use the `modify` command paired with `--bump` or `-b` flags and at least 1 target.

```sh
# Bump up any version

$ mag modify --bump --major  -  version 1.1.1+1 becomes 2.0.0+1

$ mag modify -b --major  -  version 1.1.1+1 becomes 2.0.0+1  # same as above but relatively shorter

$ mag modify -b --minor  -  version 1.1.1+1 becomes 1.2.0+1

$ mag modify -b --patch  -  version 1.1.1+1 becomes 1.1.2+1

$ mag modify -b --build-number  -  version 1.0.0+1 becomes 1.0.0+2

```

* Bump down any version by 1. You have to use the `modify` command paired with `--dump` or `-d` flags and at least 1 target. Consider using the `change` command to revert your version to a lower value than the current one. 

```sh
# Bump down any version

$ mag modify --dump --major  -  version 2.1.1+1 becomes 1.0.0+1

$ mag modify -d --major  -  version 2.1.1+1 becomes 1.0.0+1  # same as above but shorter

$ mag modify -d --minor  -  version 1.1.1+1 becomes 1.0.0+1

$ mag modify -d --patch  -  version 1.1.1+1 becomes 1.1.0+1

$ mag modify -d --build-number  -  version 1.0.0+2 becomes 1.0.0+1

```

* Change a specific node in your yaml file. You have to use the `change` command and provide a node and its new value to change it. Flutter/Dart yaml node supported currently are : `name`,  `description`,  `version`,  `homepage`,  `repository`,  `issue_tracker`,  `documentation`. You can also change the prerelease info using `set-prerelease` and build metadata using `set-build`


``` sh
# Change current version to an entirely different version. 

$ mag change --name="Hello World Project" # name is change to Hello World Project

# This applies to all nodes listed above.

```

## Dynamic Usage

* You can combine various targets in the `modify` command.

``` sh
# Bump up major and minor versions using absolute versioning

$ mag -b --major --minor --absolute  -  version 1.0.0 becomes 2.1.0

# Bump down minor, patch and build-number versions using absolute versioning

$ mag -d --minor --patch --build-number --absolute  -  version 2.2.1+18 becomes 2.1.0+17

# Bump down the major and build-number versions using absolute versioning

$ mag -d --build-number --major --absolute  -  version 2.0.1+14 becomes 1.0.1+13

```

Notice how in the last example the sequence of the targets doesn't matter. As long as the flag is a recognized target, the version will be modified accordingly.

* You can nudge the CLI and tell it not to check the current directory for the pubspec.yaml file with the `--with-path` flag. The CLI will prompt you for the path. You need to provide the directory + yaml file.

```md
path specified will be `directory-with-yaml/myFile.yaml`
```

``` sh
# Bump up with specified path

$ mag modify -b --major --with-path  -  requests path and version 1.0.0 becomes 2.0.0

```

* Alternatively you can provide a path directly with `set-path`

``` sh
# Bump up with specified path

$ mag modify -b --major --set-path=path-to-file  -  reads from path and version 1.0.0 becomes 2.0.0

```
