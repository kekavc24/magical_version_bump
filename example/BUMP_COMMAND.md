# Bump Subcommand

This subcommand is part of the `modify` command and bumps the version in your yaml/json files.

## Available flags & options

<table>
    <tr>
        <th>Name</th>
        <th style="text-align: center;">Type</th>
        <th style="text-align: center;">Abbreviation</th>
        <th style="text-align: center;">Alias</th>
        <th style="text-align: center;">Allowed values</th>
        <th style="text-align: center;">Default value</th>
    </tr>
    <tr>
        <td>targets</td>
        <td style="text-align: center;">multiOption</td>
        <td style="text-align: center;">-</td>
        <td style="text-align: center;">dict</td>
        <td>major, minor, patch, build-number</td>
        <td style="text-align: center;">-</td>
    </tr>
    <tr>
        <td>strategy</td>
        <td style="text-align: center;">option</td>
        <td style="text-align: center;">-</td>
        <td style="text-align: center;">-</td>
        <td style="text-align: center;">relative, absolute</td>
        <td style="text-align: center;">relative</td>
    </tr>
    <tr>
        <td>preset</td>
        <td style="text-align: center;">flag</td>
        <td style="text-align: center;">p</td>
        <td style="text-align: center;">-</td>
        <td style="text-align: center;">-</td>
        <td style="text-align: center;">-</td>
    </tr>
    <tr>
        <td>set-version</td>
        <td style="text-align: center;">option</td>
        <td style="text-align: center;">-</td>
        <td style="text-align: center;">ver</td>
        <td style="text-align: center;">-</td>
        <td style="text-align: center;">-</td>
    </tr>
    <tr>
        <td>set-prerelease</td>
        <td style="text-align: center;">option</td>
        <td style="text-align: center;">-</td>
        <td style="text-align: center;">pre</td>
        <td style="text-align: center;">-</td>
        <td style="text-align: center;">-</td>
    </tr>
    <tr>
        <td>set-build</td>
        <td style="text-align: center;">option</td>
        <td style="text-align: center;">-</td>
        <td style="text-align: center;">build</td>
        <td style="text-align: center;">-</td>
        <td style="text-align: center;">-</td>
    </tr>
    <tr>
        <td>keep-pre</td>
        <td style="text-align: center;">flag</td>
        <td style="text-align: center;">-</td>
        <td style="text-align: center;">-</td>
        <td style="text-align: center;">-</td>
        <td style="text-align: center;">-</td>
    </tr>
    <tr>
        <td>keep-build</td>
        <td style="text-align: center;">flag</td>
        <td style="text-align: center;">-</td>
        <td style="text-align: center;">-</td>
        <td style="text-align: center;">-</td>
        <td style="text-align: center;">-</td>
    </tr>
    <tr>
        <td>request-path</td>
        <td style="text-align: center;">flag</td>
        <td style="text-align: center;">-</td>
        <td style="text-align: center;">reqPath</td>
        <td style="text-align: center;">-</td>
        <td style="text-align: center;">-</td>
    </tr>
    <tr>
        <td>directory</td>
        <td style="text-align: center;">option</td>
        <td style="text-align: center;">-</td>
        <td style="text-align: center;">dir</td>
        <td style="text-align: center;">-</td>
        <td style="text-align: center;">-</td>
    </tr>
</table>

## Key Highlights

- `multiOption` allows you to declare multiple values for an option whereas `option` will capture last value declared if available.
- `targets` currently only allows any/all of major, minor, patch and build-number
- `strategy` - indicates whether to bump each version target independently or as a whole.

## Preface

Consider this sentence, `I want you to update my computer`.

If we were to analyze it, it is subjective to say that there is an action and a target in the sentence.

``` text
update - ACTION

my computer - TARGET
```

Thus, by using this CLI tool, you are portrayed in the sentence below:

`I want you to modify, by bumping up/down, my pubspec.yaml's major/minor/patch/build-number version` where :

```text
modify, by bumping up/down - ACTION

my pubspec.yaml's major/minor/patch/build-number version - TARGET

```

## Basic Usage

- By default, the tool uses the versioning strategy specified [here](https://semver.org/).

```bash
mag modify bump --target "major"
# Version 1.1.3 becomes 2.0.0

mag modify bump --target "minor" 
# Version 1.1.3 becomes 1.2.0

mag modify bump --target "patch" 
# Version 1.1.3 becomes 1.1.4

mag modify bump --target "build-number" 
# Version 1.1.3+2 becomes 1.1.3+3
```

- If no build number is passed in, the tool will append 0 and bump it.

```bash
mag modify bump --target "build-number"  
# Version 1.1.3 becomes 1.1.3+1
```

- If you want each version to be bumped independently, pass in the `--absolute` flag.

```bash
mag modify bump --target "major" --strategy "absolute"
# Version 1.1.3 becomes 2.1.3

mag modify bump --target "minor" --strategy "absolute"
# Version 1.1.3 becomes 1.2.3

mag modify bump --target "patch" --strategy "absolute"
# Version 1.1.3 becomes 1.1.4

mag modify bump --target "build-number" --strategy "absolute"
# Version 1.1.3+2 becomes 1.1.3+3

```

## Advanced Usage

- You can chain multiple targets to be bumped. However, the default strategy will get the target with the highest weight. Passing in the `--absolute` flag will nudge the tool to target each independently.

```bash

mag modify bump --target "major,minor,patch" 
# Version 1.8.9 becomes 2.0.0 
# major version has the highest weight
# major -> minor -> patch -> build-number

mag modify --target "major,minor,patch" --strategy "absolute" 
# Version 1.8.9 becomes 2.9.10
# Each version is bumped independently.

```

- In case your yaml file is in a different directory, use the `with-path` flag or `set-path` option. You have to include the yaml file in the directory provided.

```bash

mag modify bump --target "major" --request-path
# Will request path from you in an interactive way in the console

mag modify bump --target "major" --directory="my-path/pubspec.yaml" 
# Automatically checks directory specified

```

- By default, `set-version` sets a new version before bumping to desired version

```bash

# Initial version 1.8.9

mag modify bump --set-version="2.8.4" --target "major"
# Version changed to 2.8.4 first
# Version then bumped to 3.0.0

# It also works with absolute

mag modify bump --set-version="2.8.4" --target "major" --strategy "absolute"
# Version changed to 2.8.4 first
# Version then bumped to 3.8.4

```

- `set-version` removes any build & prerelease info from version being replaced. To keep previous build or prerelease info, pass in the `--keep-build` and `--keep-pre` flags respectively. You don't have to use them together. These flags can be used separately.

```bash

# Initial version 1.8.9-alpha+22

mag modify bump --set-version="2.8.4" --target "major" --keep-build 
# Version changed to 2.8.4 first
# Version then bumped to 3.0.0+22. Old build metadata is appended & prerelease info removed


mag modify bump --set-version="2.8.4" --target "major" --keep-pre
# Version changed to 2.8.4 first
# Version then bumped to 3.0.0-alpha. Prerelease info is appended & old build metadata is removed


mag modify bump --set-version="2.8.4" --target "major" --keep-build --keep-pre
# Version changed to 2.8.4 first
# Version then bumped to 3.0.0-alpha+22. Both the old build metadata & prerelease info are appended

```

- You can also preset the build and prerelease info if you need to perform any action on the build metadata. Use the `preset` flag to nudge tool to preset them before bumping anything.

```bash

# Initial version 1.8.9

mag modify bump --preset --set-version="2.8.4" --set-prerelease="dev.2" --set-build=10 --target "major,build-number"
# Version changed to 2.8.4-dev.2+10
# Version then bumped to 3.0.0+11
# Prerelease info is removed since we are bumping up to a major version

```

- You can also preset only the version first then append the prerelease and metadata info. Just remove/do not pass in the `preset` flag.

```bash

# Initial version 1.8.9

mag modify bump --set-version="2.8.4" --set-prerelease="dev.2" --set-build=10 --target "major"
# Version changed to 2.8.4
# Version then bumped to 3.0.0
# Prerelease info & build metadata appended after
# Version becomes 3.0.0-dev.2+10

```
