# LFA - Lambda Function Adapter

LFA is a web application framework in Ruby (Rack framework), to run AWS Lambda functions (migrated from AWS API Gateway integration) on Ruby's application servers (Unicorn, Puma, etc).

The main purposes of LFA are:

* run Lambda functions on EC2 (or container hosting services) **temporarily**
* test Lambda function as web request handler on our laptop

LFA was initially designed as a software for webapp hosting platform migration from AWS Lambda to EC2/ECS/k8s/etc by moving functions to app servers as-is. This provides time to engineers for re-implemention of native stand alone web applications.

The 2nd purpose (testing on laptop) was found eventually on the development of LFA. We can't test web request handlers of AWS Lambda functions on our laptop directly (because we don't have local API Gateway), but we can do it locally with LFA on laptop. This MAY improve our dev-experience a little, or more.

## Features

LFA mounts Lambda functions on request paths, and routes requests to those functions.

Lambda functions are:

* mounted on specified paths, by AWS Lambda's handler specification `funcfile.Modname.method_name`
* configured by `ENV` environment variables (just like AWS Lambda)
* called with `event` and `context` arguments per HTTP request (translated from Rack `env`)

LFA uses a YAML file to:

* configure functions with those environment variables
* configure resource-function relations (just like AWS API Gateway)

Functions on LFA will be loaded in (semi-)isolated module spaces. Functions will not effect to other functions (at least, unintentionally).

### Features not supported yet

The features below are not supported yet, but will be implemented eventually.

* Parameterized resource paths (e.g., `/api/resource/{resourceId}`
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

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/tagomoris/LFA.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
