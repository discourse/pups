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
