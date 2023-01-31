# frozen_string_literal: true

require_relative 'adapter/executor'
require_relative 'adapter/lambda_rack_bridge'
require_relative 'adapter/environment'

__original_warning_level = $VERBOSE
begin
  $VERBOSE = nil
  ::ENV = LFA::Adapter::EnvMimic.new
ensure
  $VERBOSE = __original_warning_level
end

module LFA
  class Adapter
    def initialize(resolver)
      @resolver = resolver
      @executors = {}
    end

    include LambdaRackBridge

    def call(env)
      begin
        path = request_path(env: env)
        method = http_method(env: env)

        matched = @resolver.resolve(path, method)
        unless matched
          return [404, {}, ["Resource not found"]]
        end
        function = matched.function
        executor = @executors.fetch(function.name){ Executor.setup(function) }
        unless @executors.has_key?(function.name)
          @executors[function.name] = executor
        end

        event = lambda_event(env: env, path_parameters: matched.path_parameters.dup)
        context = lambda_context(function_name: function.name)

        result = executor.call(event: event, context: context)
        return convert_to_rack_response(result) # => [200, {}, ["OK"]]
      rescue => e
        p(here: "unexpected error", error_class: e.class, error: e.message)
        puts e.backtrace
        return [500, {}, ["Internal Server Error"]]
      end
    end
  end
end
