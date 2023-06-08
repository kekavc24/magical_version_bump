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

## Modify Command
- This command is versatile and can be used to change or modify the version in your pubspec.yaml.
- You need to specify an `action` and a `target` when bumping your version. The `action` flag must be specified first. Either `--bump` or `-b`.

### Basic Usage
- By default, the tool uses the versioning strategy specified [here](https://semver.org/). 

```sh
mag modify --bump --major # Version 1.1.3 becomes 2.0.0

mag modify --bump --minor # Version 1.1.3 becomes 1.2.0

mag modify --bump --patch # Version 1.1.3 becomes 1.1.4

mag modify --bump --build-number # Version 1.1.3+2 becomes 1.1.3+3

```

- If no build number is passed in, the tool will append 1 and bump it.

```sh

mag modify --bump --build-number # Version 1.1.3 becomes 1.1.3+2

```

- If you want each version to be bumped independently, pass in the `--absolute` flag.

```sh
mag modify --bump --major --absolute # Version 1.1.3 becomes 2.1.3

mag modify --bump --minor --absolute # Version 1.1.3 becomes 1.2.3

mag modify --bump --patch --absolute # Version 1.1.3 becomes 1.1.4

mag modify --bump --build-number --absolute # Version 1.1.3+2 becomes 1.1.3+3

```

### Advanced Usage

- You can chain multiple targets to be bumped. However, the default strategy will get the target with the highest weight. Passing in the `--absolute` flag will nudge the tool to target each independently.

```sh

# You can also use the shorthand -b instead of --bump
mag modify -b major minor patch # Version 1.8.9 becomes 2.0.0 

# major version has the highest weight
# major -> minor -> patch -> build-number

mag modify -b major minor patch --absolute # Version 1.8.9 becomes 2.9.10

# Each version is bumped independently.

```


- In case your yaml file is in a different directory, use the `with-path` flag or `set-path` option. You have to include the yaml file in the directory provided.

```sh

mag modify -b major --with-path # Will request path from you in an interactive way in the console

mag modify -b major --set-path="my-path/pubspec.yaml" # Automatically checks directory specified

```


- By default, `set-version` sets a new version before bumping to desired version

```sh

# Initial version 1.8.9

mag modify --set-version=2.8.4 -b major 

# Version changed to 2.8.4 first
# Version then bumped to 3.0.0

# It also works with absolute

mag modify --set-version=2.8.4 -b major --absolute

# Version changed to 2.8.4 first
# Version then bumped to 3.8.4

```


- `set-version` removes any build & prerelease info from version being replaced. To keep previous build or prerelease info, pass in the `--keep-build` and `--keep-pre` flags respectively. You don't have to use them together. These flags can be used separately.

```sh

# Initial version 1.8.9-alpha+22

mag modify --set-version=2.8.4 -b major --keep-build 
# Version changed to 2.8.4 first
# Version then bumped to 3.0.0+22. Old build metadata is appended & prerelease info removed


mag modify --set-version=2.8.4 -b major --keep-pre
# Version changed to 2.8.4 first
# Version then bumped to 3.0.0-alpha. Prerelease info is appended & old build metadata is removed


mag modify --set-version=2.8.4 -b major --keep-build --keep-pre
# Version changed to 2.8.4 first
# Version then bumped to 3.0.0-alpha+22. Both the old build metadata & prerelease info are appended

```


- You can also preset the build and prerelease info if you need to perform any action on the build metadata. Use the `preset` flag to nudge tool to preset them before bumping anything.

```sh

# Initial version 1.8.9

mag modify --preset --set-version=2.8.4 --set-prerelease="dev.2" --set-build=10 --bump --major --build-number
# Version changed to 2.8.4-dev.2+10
# Version then bumped to 3.0.0+11
# Prerelease info is removed since we are bumping up to a major version


```


- You can also preset only the version first then append the prerelease and metadata info. Just remove/do not pass in the `preset` flag.

```sh

# Initial version 1.8.9

mag modify --set-version=2.8.4 --set-prerelease="dev.2" --set-build=10 --bump --major
# Version changed to 2.8.4
# Version then bumped to 3.0.0
# Prerelease info & build metadata appended after
# Version becomes 3.0.0-dev.2+10

```

## Change Command
This command is straight-forward and modifies nodes in your yaml file. The nodes currently supported include:
- name - `--name` 
- description - `--description`
- version - `--yaml-version`, `--set-version`
- homepage url - `--homepage` 
- repository url - `--repository` 
- issue-tracker url - `--issue_tracker`
- documentation url - `--documentation`

* Specify an accepted option and pass in a value

```sh

mag change --name="My new name"
# Your project name changes to "My new name"

```
