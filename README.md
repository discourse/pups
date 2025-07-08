# pups

Simple YAML--based bootstrapper

## Installation

Add this line to your application's Gemfile:

    gem 'pups'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install pups

## Usage

pups is a small library that allows you to automate the process of creating Unix images.

```
Usage: pups [options] [FILE|--stdin]
        --stdin                      Read input from stdin.
        --quiet                      Don't print any logs.
        --ignore <elements>          Ignore specific configuration elements, multiple elements can be provided (comma-delimited).
                                     Useful if you want to skip over config in a pups execution.
                                     e.g. `--ignore env,params`.
        --tags <elements>            Only run tagged commands.
        --skip-tags <elements>       Run all but listed tagged commands.
        --gen-docker-run-args        Output arguments from the pups configuration for input into a docker run command. All other pups config is ignored.
    -h, --help
```

pups requires input either via a stdin stream or a filename. The entire input is parsed prior to any templating or command execution.

Example:

```
# somefile.yaml
params:
  hello: hello world

run:
  - exec: /bin/bash -c 'echo $hello >> hello'
```

Running: `pups somefile.yaml` will execute the shell script resulting in a file called "hello" with the contents "hello world".

### Features

#### Filtering run commands by tags

The `--tags` and `--skip-tags` argument allows pups to target a subset of commands listed in the somefile.yaml. To use this, you may tag your commands in the runblock. `--tags` will only run commands when commands have a matching tag. `--skip-tags` will skip when commands have a matching tag.

Note, hooks from tagged commands will be present or absent depending on if the tag is filtered out or not as well. A command filtered out by targeting tag will also filter out the command's `before_` and `after_` hooks.

Example:

```
# somefile.yaml

run:
  - exec:
      cmd: /bin/bash -c 'echo hello >> hello'
      tag: sometag
  - exec:
      cmd: /bin/bash -c 'echo hi >> hello'
      tag: anothertag
  - exec:
      cmd: /bin/bash -c 'echo goodbye >> hello'
      tag: thirdtag
```
Running: `pups --tags="sometag,anothertag" somefile.yaml` will not run the echo goodbye statement.

Running: `pups --skip-tags="sometag,anothertag" somefile.yaml` will ONLY run the echo goodbye statement.

#### Parameter overriding

The `--params` argument allows pups to dynamically override params set within a configuration for the single pups run.

Note, it is expected to be of the form `key=value`. If it is malformed, a warning will be thrown.

Example:

```
# somefile.yaml

params:
  param1: false_prophet
  param2: also overridden
run:
  - exec:
      cmd: /bin/bash -c 'echo $param1 $param2 >> hello'
```
Running `pups --params="param1=true_value,param2=other_true_value" somefile.yaml` will overwrite param1 and param2 with true_value and other_true_value respectively

#### Docker run argument generation

The `--gen-docker-run-args` argument is used to make pups output arguments be in the format of `docker run <arguments output>`. Specifically, pups
will take any `env`, `volume`, `labels`, `links`, and `expose` configuration, and coerce that into the format expected by `docker run`. This can be useful
when pups is being used to configure an image (e.g. by executing a series of commands) that is then going to be run as a container. That way, the runtime and image
configuration can be specified within the same yaml files.


#### Environment Variables

By default, pups automatically imports your environment variables and includes them as params.

```
# In bash
export SECRET_KEY="secret value"

# In somefile.yaml
run:
  - exec: echo "$SECRET_KEY"
```

Running the above code with pups will produce `secret value`.

#### Execution

Run multiple commands in one path:

```
run:
  - exec:
      cd: some/path
      cmd:
        - echo 1
        - echo 2
```

Run commands in the background (for services etc)

```
run:
  - exec:
      cmd: /usr/bin/sshd
      background: true
```

Suppress exceptions on certain commands

```
run:
  - exec:
      cmd: /test
      raise_on_fail: false
```

#### Replacements:

```
run:
  - replace:
      filename: "/etc/redis/redis.conf"
      from: /^pidfile.*$/
      to: ""
```

Will substitute the regex with blank, removing the pidfile line

```
run:
  - replace:
      filename: "/etc/nginx/conf.d/discourse.conf"
      from: /upstream[^\}]+\}/m
      to: "upstream discourse {
        server 127.0.0.1:3000;
      }"
```

Additional params:

Global replace (as opposed to first match)
```
global: true
```

#### Hooks

Execute commands before and after a specific command by defining a hook.

```
run
  - exec:
      hook: hello
      cmd: echo 'Hello'

hooks:
  before_hello:
    - exec:
        cmd: echo 'Starting...'

  after_hello:
    - exec:
        cmd: echo 'World'
```

#### Merge yaml files

```
home: /var/www/my_app
params:
  database_yml:
    production:
      username: discourse
      password: foo

run:
  - merge: $home/config/database.yml $database_yml

```

Will merge the yaml file with the inline contents.

#### A common environment

Environment variables can be specified under the `env` key, which will be included in the environment for the template.

```
env:
  MY_ENV: "a couple of words"
run:
  - exec: echo $MY_ENV > tmpfile
```

`tmpfile` will contain `a couple of words`.

You can also specify variables to be templated within the environment, such as:

```
env:
  greeting: "hello, {{location}}!"
env_template:
  location: world
```

In this example, the `greeting` environment variable will be set to `hello, world!` during initialisation as the `{{location}}` variable will be templated as `world`.
Pups will also look in the environment itself at runtime for template variables, prefixed with `env_template_<variable name>`.
Note that strings should be quoted to prevent YAML from parsing the `{ }` characters.

All commands executed will inherit the environment once parsing and variable interpolation has been completed.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
