# frozen_string_literal: true

require_relative '../handler/cors'

module LFA
  class Adapter
    class Executor
      BUILT_IN_HANDLERS = {
        'CORS' => Handler::CORSPreflight,
      }

      def self.setup(function)
        if function.handler.builtin?
          BUILT_IN_HANDLERS[function.handler.name].new(function.params)
        else
          env = Hash[*(function.env.map{|k,v| [k.to_s, v] }.flatten)]
          Executor.new(function.name, env, function.handler)
        end
      end

      def initialize(name, env, handler)
        @name = name
        @env = env
        @klass = handler.klass.to_s
        # @klass must be a string because `const_get(:"A::B")` is not resolved
        # https://bugs.ruby-lang.org/issues/12319
        @method = handler.method.to_sym

        @enclosure = Module.new
        @enclosure.const_set(:ENV, @env)
        m1 = Module.new
        m1.const_set(:ENV, @env)
        path = handler.path
        ENV.mimic!(@env) do
          load(path, @enclosure)
        end
        @handler_instance = @enclosure.const_get(@klass)
        raise "failed to load the handler module '#{@klass}'" unless @handler_instance
        @handler_method = @handler_instance.method(@method)
      end

      def call(event:, context:)
        ENV.mimic!(@env) do
          @handler_method.call(event: event, context: context)
        end
      end
    end
  end
end
