# Set Subcommand

This subcommand is part of the `modify` command and overwrites/appends to nodes in your yaml/json files.

## Available flags & options

<table>
    <tr>
        <th>Name</th>
        <th style="text-align: center;">Type</th>
        <th style="text-align: center;">Abbreviation</th>
        <th style="text-align: center;">Alias</th>
    </tr>
    <tr>
        <td>dictionary</td>
        <td style="text-align: center;">multiOption</td>
        <td style="text-align: center;">-</td>
        <td style="text-align: center;">dict</td>
    </tr>
    <tr>
        <td>add</td>
        <td style="text-align: center;">multiOption</td>
        <td style="text-align: center;">-</td>
        <td style="text-align: center;">-</td>
    </tr>
    <tr>
        <td>set-version</td>
        <td style="text-align: center;">option</td>
        <td style="text-align: center;">-</td>
        <td style="text-align: center;">ver</td>
    </tr>
    <tr>
        <td>set-prerelease</td>
        <td style="text-align: center;">option</td>
        <td style="text-align: center;">-</td>
        <td style="text-align: center;">pre</td>
    </tr>
    <tr>
        <td>set-build</td>
        <td style="text-align: center;">option</td>
        <td style="text-align: center;">-</td>
        <td style="text-align: center;">build</td>
    </tr>
    <tr>
        <td>keep-pre</td>
        <td style="text-align: center;">flag</td>
        <td style="text-align: center;">-</td>
        <td style="text-align: center;">-</td>
    </tr>
    <tr>
        <td>keep-build</td>
        <td style="text-align: center;">flag</td>
        <td style="text-align: center;">-</td>
        <td style="text-align: center;">-</td>
    </tr>
    <tr>
        <td>request-path</td>
        <td style="text-align: center;">flag</td>
        <td style="text-align: center;">-</td>
        <td style="text-align: center;">reqPath</td>
    </tr>
    <tr>
        <td>directory</td>
        <td style="text-align: center;">option</td>
        <td style="text-align: center;">-</td>
        <td style="text-align: center;">dir</td>
    </tr>
</table>

## Key Highlights

- `multiOption` allows you to declare multiple values for an option whereas `option` will capture last value declared if available.
- `dictionary` will overwrite any existing nodes or create new nodes entirely if missing with values passed.
- `add` will append values to any existing nodes or create new nodes entirely.
- `set-version`, `set-prerelease` and `set-build` target the "version" node in your yaml/json file.
- `request-path` will prompt you for the path interactively.
- `directory` will indicate to tool where to find yaml/json/text file.

Custom delimiters when specifying values include:

- `=` - points key to values
- `|` - allows you to declare multiple keys that will act as a path to the data
- `,` - indicates a list of values
- `->` - allows you to declare a map

### Example file

Consider a pubspec.yaml file saved as:

``` yaml
name: Fake Yaml
description: A yaml file for testing
version: 1.0.0
```

## Basic usage

### Adding a new node with one value

```bash

mag modify set --dictionary "test=This is a test"

# Or

mag modify set --dict "test=This is a test"

```

[File](#example-file) output will be :

``` yaml
name: Fake Yaml
description: A yaml file for testing
version: 1.0.0
test: This is a test
```

### Adding a new node with list of values

```bash

mag modify set --dictionary "test=value,anotherValue"

# Or

mag modify set --dict "test=value,anotherValue"

# This also works with map of values

```

[File](#example-file) output will be :

``` yaml
name: Fake Yaml
description: A yaml file for testing
version: 1.0.0
test: 
    - value
    - anotherValue
```

### Adding a new node with map

```bash

mag modify set --dictionary "test=value->anotherValue"

# Or

mag modify set --dict "test=value->anotherValue"

```

[File](#example-file) output will be :

``` yaml
name: Fake Yaml
description: A yaml file for testing
version: 1.0.0
test: 
    value: anotherValue
```

### Overwriting an existing node

You can use all tricks specified above to replace an existing node.

```bash

# Change "name" node to new value
mag modify set --dict "name=test"

# Change "name" node to list of values
mag modify set --dict "name=test,anotherTest"

# Change "name" node to list of maps
mag modify set --dict "name=test->anotherTest"

```

### Overwriting version

```bash

mag modify set --set-version "2.0.0"

# Or

mag modify set --ver "2.0.0"

```

[File](#example-file) output will be :

``` yaml
name: Fake Yaml
description: A yaml file for testing
version: 2.0.0
```

### Overwriting pre-release

```bash

mag modify set --set-prerelease "alpha"

# Or

mag modify set --pre "alpha"

```

[File](#example-file) output will be :

``` yaml
name: Fake Yaml
description: A yaml file for testing
version: 1.0.0-alpha
```

### Overwriting build number

```bash

mag modify set --set-build "21"

# Or

mag modify set --build "21"

```

[File](#example-file) output will be :

``` yaml
name: Fake Yaml
description: A yaml file for testing
version: 1.0.0+21
```

## Advanced Usage

In certain instances, you may need to append new values to existing nodes. This is easily achievable with the `add` multi-option.

Certain constraints are put in place to prevent misuse such as:

1. You cannot append a map to a key with a single value or list of values.
2. You can only append a map to a key with other maps of values.
3. You can only append a string/list of values to a key with a single value or list of values.

### Appending a value to existing node

```bash

mag modify set --add "description=This is a test"

```

[File](#example-file) output will be :

``` yaml
name: Fake Yaml
description: 
    - A yaml file for testing
    - This is a test
version: 1.0.0
```

### Nested keys

You can create/append to nested keys using `|` . Consider the yaml file below :

```yaml
root-key:
    nested-key: value
    nested-list:
        - value
        - anotherValue
    nested-map:
        nested-value: value
```

- You can overwrite either `nested-key`, `nested-list` or `nested-map` by:

```bash

# Overwrite "nested-key"
mag modify set --dict "root-key|nested-key=newValue"

# Overwrite "nested-list"
mag modify set --dict "root-key|nested-list=newValue,anotherNewValue"

# Overwrite "nested-map"
mag modify set --dict "root-key|nested-map=new-map->newValue"

# Overwrite them all in sequence
mag modify set --dict "root-key|nested-key=newValue" --dict "root-key|nested-list=newValue,anotherNewValue" --dict "root-key|nested-map=new-map->newValue"

```

Depending on which example you use from above, the final file will be:

```yaml

# Overwrite "nested-key"
root-key:
    nested-key: newValue
    nested-list:
        - value
        - anotherValue
    nested-map:
        nested-value: value

# Overwrite "nested-list"
root-key:
    nested-key: value
    nested-list:
        - newValue
        - anotherNewValue
    nested-map:
        nested-value: value

# Overwrite "nested-map"
root-key:
    nested-key: value
    nested-list:
        - value
        - anotherValue
    nested-map:
        new-map: newValue

# Overwrite them all in sequence
root-key:
    nested-key: newValue
    nested-list:
        - newValue
        - anotherNewValue
    nested-map:
        new-map: newValue
```

- You can append to existing keys too.

```bash

# Append to "nested-key"
mag modify set --add "root-key|nested-key=newValue"

# Append to "nested-list"
mag modify set --add "root-key|nested-list=newValue,anotherNewValue"

# Append to "nested-map"
mag modify set --add "root-key|nested-map=new-map->newValue"

# Append to them all in sequence
mag modify set --add "root-key|nested-key=newValue" --add "root-key|nested-list=newValue,anotherNewValue" --add "root-key|nested-map=new-map->newValue"

```

Depending on which example you use from above, the final file will be:

```yaml

# Append to "nested-key"
root-key:
    nested-key: 
        - value
        - newValue
    nested-list:
        - value
        - anotherValue
    nested-map:
        nested-value: value

# Append to "nested-list"
root-key:
    nested-key: value
    nested-list:
        - value
        - anotherValue
        - newValue
        - anotherNewValue
    nested-map:
        nested-value: value

# Append to "nested-map"
root-key:
    nested-key: value
    nested-list:
        - value
        - anotherValue
    nested-map:
        nested-value: value
        new-map: newValue

# Append to them all in sequence
root-key:
    nested-key: 
        - value
        - newValue
    nested-list:
        - value
        - anotherValue
        - newValue
        - anotherNewValue
    nested-map:
        nested-value: value
        new-map: newValue
```

### Other tricks

`dict` is quite versatile and can be used to change a node that only accepts maps to accept a value/list of values and vice versa.

- For example, we can make the `root-key` from the example yaml file [here](#nested-keys) to accept a list of values we want to pass in by doing:

```bash
mag modify set --dict "root-key=value" --add "root-key=another,thirdOther"
```

Updated file will look like so:

```yaml
root-key: 
    - value
    - another
    - thirdOther
```

- Furthermore, make the nested key `nested-key` accept a map of values like so:

```bash
mag modify set --dict "root-key|nested-key=map->value" --add "root-key=anotherMap->value,otherMap->value"
```

Updated file will look like so:

```yaml
root-key:
    nested-key:
       map: value
       anotherMap: value
       otherMap: value
    nested-list:
        - value
        - anotherValue
    nested-map:
        nested-value: value
```

**NOTE** : `dictionary` or `dict` option overwrites a key's value thus its use on an anchor key will remove any nested keys!
