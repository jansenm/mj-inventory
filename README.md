# MJ Inventory

![CI](https://github.com/jansenm/mj-inventory/actions/workflows/ci.yml/badge.svg)

MJ Inventory is a lightweight configuration management database (cmdb) implementation. One of its main use cases is to
replace the build-in inventory of ansible or as an external node classifier(enc) in puppet.

It is also possible to use it for completely different purposes. For example to hold the configuration of a Jenkins
Job-DSL Job to generate 100s of Jobs automatically.

This software is heavily inspired by [reclass] because that is what I currently use. In future i will extend the
functionality but will always provide a reclass compatibility mode.

## Concepts

### Node

A node is a concrete item. It represents all the concrete items you need to act upon.

For example a host that should be deployed, or just an account on a host you need to target. Perhaps a piece of software
you want to build.

### Class

A class is an abstract concept. You can then apply those abstract concepts to your nodes by inheritance.

Something like

- Role
- Category
- Marker
- Trait

### Repository

A repository is one unit of configuration that can contain many classes and nodes. Currently, the only implemented
option is file based repositories but there are ideas and plans to implement database backed repositories.

The repository is a directory containing two other directories.

```shell
~# ls repository
classes/
nodes/
```

### Inheritance

Nodes and classes can inherit from classes. The configuration of the child will be merged into the configuration of the
base class following a clear set of rules leading to reproducible and predictable results.

### Inheritance Chain

MJ Repository supports multiple inheritance. It is well-defined. The inheritance chain is the resulting order in which
the objects are merged left to right.

### Interpolation

After the inheritance chain was determined, and the configurations successfully merged in a last step interpolation will
be done. Interpolation allows cross-referencing configuration values to avoid duplication.

```yaml
parameters:
  host:
    name: myserver
    ip-address: 127.0.0.1
  motd: |-
    Welcome to ${host:name} ${host:ip-address}
```

After interpolation, the value of *motd* is "Welcome to myserver 127.0.0.1".

## Rules

### Naming

The name of a object is derived from its filesystem path. The rules are:

**For classes** the path under the classes directory becomes the name with all slashes substituted with a dot.

| Path | Name |
| ---- | ---- |
| $REPO/classes/distribution/opensuse.yml | distribution.opensuse |
| $REPO/classes/domain/michael-jansen.biz.yml | domain.michael-jansen.biz |

The rule stems from reclass. I personally don't like it because as the second example shows you can't infer the path
back from the resulting name.

**For nodes** the filename becomes the name. Subdirectories under nodes are discarded.

| Path | Name |
| ---- | ---- |
| $REPO/nodes/host/michael-jansen.biz.yml | michael-jansen.biz |

The namespaces of nodes and classes are distinct. It is possible to have a node and class with the same name.

### Inheritance Chain

The inheritance chain is determined according to the following rule.

* The classes are merged depth first in the order they appear in the file.
* A class is ignored if it is encountered a second time.
* A recursive inheritance chain is a non-recoverable error.

Example:

```yaml
# class baseA
classes:
```

```yaml
# class baseB
classes:
  - baseA
```

```yaml
# node nodeA
classes:
  - baseB
  - baseA
```

Even if **nodeA** inherits *baseA* after *baseB* the effective inheritance chain is *baseA*, *baseB* and then *nodeA*
because *baseB* inherits *baseA* effectively moving *baseA* in front of itself.

### Inheritance Rules

The rules are simple.

#### Lists are appended

```yaml
# class baseA
parameters:
  list:
    - A
```

```yaml
# class baseB
classes:
  - baseA
parameters:
  list:
    - B
```

```yaml
# node nodeA
classes:
  - baseB
  - baseA
parameters:
  list:
    - C
```

Merging the lists in the order of the inheritance chain leads to the results of

```yaml
# node nodeA
parameters:
  list:
    - A
    - B
    - C
```

#### Maps are merged

```yaml
# class baseA
parameters:
  map:
    a: 1
```

```yaml
# class baseB
classes:
  - baseA
parameters:
  map:
    b: 2
```

```yaml
# node nodeA
classes:
  - baseB
  - baseA
parameters:
  map:
    c: 3
```

Merging the maps in the order of the inheritance chain leads to the results of

```yaml
# node nodeA
parameters:
  map:
    b: 2
    a: 1
    c: 3
```

The resulting map up there is unordered because yaml makes **NO GUARANTEE** for the order of maps.

#### Values with different data types overwrite

```yaml
# class baseA
parameters:
  map:
    a: 1
```

```yaml
# node nodeA
classes:
  - baseA
parameters:
  map: "A map"
```

Merging the values in the order of the inheritance chain leads to the results of

```yaml
# node nodeA
parameters:
  map: "A map"
```

The scalar in  *nodeA* can not be merged into the map, so it overwrites it.

#### Lists and Maps can be overwritten

```yaml
# class baseA
parameters:
  list:
    - A
```

```yaml
# node nodeA
classes:
  - baseA
parameters:
  ~list:
    - C
```

Merging the lists in the order of the inheritance chain leads to the results of

```yaml
# node nodeA
parameters:
  list:
    - C
```

A *tilde* in front of the name of a list or map tells mj inventory to not merge the values but instead overwrite them.

<table>
  <tr>
    <th>:exclamation:</th>
    <td>You should use this sparingly. One could argue this breaks inheritance. It could be a hint that your
        configuration is structured wrong.</td>
  </tr>
</table>

## Usage

### Building the project

The project is a typical elixir and phoenix project. So the command to build it are:

```shell

# Get the elixir dependencies and compile them. any problem here is not related to the project
mix deps.get
mix deps.compile

# Compile the app itself
mix compile

# Build the web assets
cd apps/inventory_web && npm install --prefix assets

# Run unit tests (optional but recommended)
mix test

```

### Using the project

There are currently two usages implemented in mj inventory. The implementation aims currently to be 100% reclass
compatible making it possible to continue using reclass and just use the graphical interface for enhanced insight into
the inventory.

### Graphical User Interface

The graphical user interface gives some insight into the repo. It shows the inheritance chain and all intermediate
states of it, the values before and after interpolation plus all encountered errors.

```shell
# Start the phoenix app with a given repository
REPOSITORY=/path/to/repo mix phx.server
```

### Command line

To build the binary(escript).

```shell
cd apps/inventory && mix escript.build
```

And to use it:

```shell
# This give the reclass compatible output (one big json)
./inventory $INVENTORY_PATH

# This give the ansible compatible output
./inventory --list $INVENTORY_PATH
./inventory --host <HOST> ~$INVENTORY_PATH
```

<table>
  <tr>
    <th>:exclamation:</th>
    <td>The cli part is the most fragile right now. Needs some love.</td>
  </tr>
</table>

# Licensing

    SPDX-FileCopyrightText: 2021 Michael Jansen <info@michael-jansen.biz>
    SPDX-License-Identifier:  AGPL-3.0-or-later

[reclass]: https://reclass.pantsfullofunix.net/