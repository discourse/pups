# pups

Simple yaml based bootstrapper

## Installation

Add this line to your application's Gemfile:

    gem 'pups'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install pups

## Usage

pups is a small library that allows you to automate the process of creating Unix images.

Example:

```
# somefile.yaml
params:
  hello: hello world

run:
  exec: /bin/bash -c 'echo $hello >>> hello'
```

Running: pups somefile.yaml will exectue the shell script resulting in a file called "hello" with the "hello world" contents

### Features:

####Execution

Run multiple commands in one path:

```
run:
  exec:
    cd: some/path
    cmd:
      - echo 1
      - echo 2
```

####Replacements:

```
run:
  replace:
    filename: "/etc/redis/redis.conf"
    from: /^pidfile.*$/
    to: ""
```

Will substitued the regex with blank, removing the pidfile line

```
run:
  - replace:
      filename: "/etc/nginx/conf.d/discourse.conf"
      from: /upstream[^\}]+\}/m
      to: "upstream discourse {
        server 127.0.0.1:3000;
      }"
```

Multiline replace using regex

####Merge yaml files:

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

Will merge the yaml file with the inline contents

####A common environment

```
env:
   MY_ENV: 1
```

All executions will get this environment set up


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
