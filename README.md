# LFA - Lambda Function Adapter

**LFA is under development, and not released yet.**

LFA is a web application framework in Ruby (Rack framework), to run AWS Lambda functions (migrated from AWS API Gateway integration) on Ruby's application servers (Unicorn, Puma, etc).

The main purposes of LFA are:

* run Lambda functions on EC2 (or container hosting services) **temporarily**
* test Lambda function as web request handler on our laptop

LFA was initially designed to host webapps migrated from AWS Lambda to EC2/ECS/k8s/etc by moving functions to app servers as-is. This provides time to engineers for re-implemention of native stand alone web applications.

The 2nd purpose (testing on laptop) was found eventually during the development of LFA. We can't test web request handlers of AWS Lambda functions on our laptop directly (because we don't have local API Gateway), but we can do it locally with LFA on laptop. This MAY improve our dev-experience a little, or more.

## Features

LFA mounts Lambda functions on request paths, and routes requests to those functions.

Lambda functions are:

* mounted on specified paths, by AWS Lambda's handler specification `funcfile.Modname.method_name`
* configured by `ENV` environment variables (just like AWS Lambda)
* called with `event` and `context` arguments per HTTP request (translated from Rack `env`)

LFA uses a YAML file to:

* configure functions with those environment variables
* configure resource-function relations (just like AWS API Gateway)

Functions on LFA will be loaded in (semi-)isolated module spaces. Functions will not effect to other functions (at least, unintentionally). See "Limitations" section below about the function isolation.

### Features not supported yet

The features below are not supported yet, but will be implemented eventually.

* Parameterized resource paths (e.g., `/api/resource/{resourceId}`)
* Greedy path parameters (e.g., `/api/{proxy+}`)
* CORS support and built-in `OPTIONS` method request handler
* Loading functions from `.zip` archives

## How to run LFA

### Installation

Add LFA to your application's Gemfile:

```ruby
gem 'LFA'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install LFA

### Configuration

Write a YAML configuration file, and a `config.ru` Rack app file.

Rack app file is just to load LFA with the following YAML file.

```ruby
# config.ru
require 'LFA'
run LFA.ignition!('config.yaml')
```

The YAML configuration file is to describe application resources, and functions to be called per request. The YAML requires 2 child elements:

* `resources`: the list of nested resources, almost equal to the resources on AWS API Gateway
* `functions`: the list of functions, referred from resources

```yaml
# config.yaml
---
resources:
  - path: /api
    resources:
      - path: /country
        methods:
          GET: myfunc-countries
      - path: /data
        resources:
          - path: /csv
            methods:
              GET: myfunc-data-csv
          - path: /json
            methods:
              GET: myfunc-data-json
functions:
  - name: myfunc-countries
    handler: myfunc.Countries.process
    env:
      DATABASE_HOSTNAME: mydb.local
      DATABASE_PASSWORD: this-is-the-top-secret
  - name: myfunc-data-csv
    handler: myfunc.Data.process
    env:
      OUTPUT_DATA_TYPE: csv
  - name: myfunc-data-json
    handler: myfunc.Data.process
    env:
      OUTPUT_DATA_TYPE: json
```

The actual Lambda functions should be placed on the same directory with those configuration files.
LFA will load `Countries` module from `myfunc.rb`, then call its `process` method for the request path `/api/country`.

### Ignition

Run your Rack application as usual (for example, with `puma`):

    $ puma config.ru

Or, using `rackup` (requires `gem i rackup`)

    $ rackup --server puma config.ru

## Limitation

The separation of Lambda functions is not perfect. That means:

* The Ruby script `funcfile` of Lambda handler `funcfile.Modname.method_name` is loaded in an isolated namespace
* Libraries `require`-ed from the Lambda file are NOT isolated, and be shared by all Lambda functions in the process
* `ENV` access out of Lambda handler context in `require`-ed files will see the original `ENV`, instead of `env` configured

To avoid those limitations, the Lambda functions loaded by LFA should take care of the following things.

### Use common set of libraries

Lambda functions should use the common set of libraries. That means, Lambda functions should:

* have a common `lib` directory for its internal libraries
* have a single `Gemfile` (and `Gemfile.lock`) to use the common set of gems

If the Lambda functions are of single application, these things will be satisfied usually. Otherwise, don't share a single LFA process.

### Create handler object/module in function files

If your Lambda function's handler module is defined in `funcfile`, it's totally OK.

```ruby
# func.rb

module Modname
  def self.method_name(event:, context:)
    # ...
  end
end
# OK
```

But if the `funcfile` just requires your library and the library defines the handler module or instantiate the handler object, it MAY be NOT OK because that module/object are shared between different functions. It SHOULD be BAD when the handler object has internal states.

```ruby
# func.rb
require_relative './lib/myapp/handler'
# and it provides Modname module

# MAY be NOT OK
```

If your Lambda handler has to have internal states, you should define a class, and instantiate it in `funcfile`, as following:

```ruby
# lib/myapp/handler.rb
class MyHandler
  def initialize
    @internal_cache = {}
  end

  def process(event:, context:)
    # ...
  end
end

# func.rb
require_relative './lib/myapp/handler'
Handler = MyHandler.new

# and specify the handler: func.Handler.process
# OK!
```

### Refer ENV in dynamic manner

LFA overrides the `ENV` reference in `funcfile`.

```ruby
# func.rb
module HandlerA
  DB_HOST = ENV['DB_HOST'] # this refers configured `env`

  def process(event:, context:)
    # ...
  end
end
```

But the `ENV` reference in the static context (code not in methods) in required libraries will refer the original environment variables of the LFA process, instead of configured `env` key-value pairs.

```ruby
# func.rb
require_relative './lib/myapp/handler'
Handler = HandlerB.new

# lib/myapp/handler.rb
class HandlerB
  DB_HOST = ENV['DB_HOST'] # this refers the process's environment variables

  def process(event:, context:)
    # ...
  end
end
```

Even in libraries, code in methods called from `funcfile` will refer the configured `env`. So, `ENV` references should be written in methods, called dynamically.

```ruby
# func.rb
require_relative './lib/myapp/handler'
Handler = HandlerB.new

# lib/myapp/handler.rb
class HandlerB
  def initialize
    @db_host = ENV['DB_HOST'] # this refers the `env` configured
  end

  def process(event:, context:)
    # Or, refer ENV in this handler method
    # ...
  end
end
```

Gem libraries referring `ENV` should be initiated in methods, dynamically, as well.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/tagomoris/LFA.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
