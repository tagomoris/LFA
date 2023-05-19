# frozen_string_literal: true

module LFA
  class Adapter
    class Executor
      def self.setup(function)
        env = Hash[*(function.env.map{|k,v| [k.to_s, v] }.flatten)]
        Executor.new(function.name, env, function.handler)
      end

      def initialize(name, env, handler)
        @name = name
        @env = env
        @klass = handler.klass.to_s
        # @klass must be a string because `const_get(:"A::B")` is not resolved
        # https://bugs.ruby-lang.org/issues/12319
        @method = handler.method.to_sym

        # @enclosure = Module.new
        # @enclosure.const_set(:ENV, @env)
        m1 = Module.new
        m1.const_set(:ENV, @env)
        path = handler.path
        begin
          ENV.mimic!(@env) do
            load(path, m1)
          end
        rescue => e
          raise "failed to load the function file '#{path}': #{e.class}, #{e.message}"
        end
        @handler_instance = @enclosure.const_get(@klass)
        # @handler_instance = @enclosure.const_get(@klass)
        # raise "failed to load the handler module '#{@klass}'" unless @handler_instance
        # @handler_method = @handler_instance.method(@method)
        instance = m1.const_get(@klass)
        raise "failed to load the handler module '#{@klass}'" unless instance
        @handler_method = instance.method(@method)
      end

      def call(event:, context:)
        ENV.mimic!(@env) do
          @handler_method.call(event: event, context: context)
        end
      end
    end
  end
end
