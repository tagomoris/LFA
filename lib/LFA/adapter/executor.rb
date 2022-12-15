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
        @filename = handler.filename + ".rb"
        @klass = handler.klass.to_sym
        @method = handler.method.to_sym

        @enclosure = Module.new
        @enclosure.const_set(:ENV, @env)
        begin
          Kernel.load(@filename, @enclosure)
        rescue => e
          raise "failed to load the function file '#{@filename}': #{e.message}"
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
