# frozen_string_literal: true

module LFA
  class Adapter
    class Handler
      class CORSHandler
        def self.setup(...)
        end

        def initialize
        end

        
        #### You can specify the following parameters in a CORS configuration.
        # CORS headers                       CORS configuration property    Example values
        # Access-Control-Allow-Origin        allowOrigins                   https://www.example.com
        #                                                                   * (allow all origins)
        #                                                                   https://* (allow any origin that begins with https://)
        #                                                                   http://* (allow any origin that begins with http://)
        # Access-Control-Allow-Credentials   allowCredentials               true
        # Access-Control-Expose-Headers      exposeHeaders                  Date, x-api-id
        # Access-Control-Max-Age             maxAge                         300
        # Access-Control-Allow-Methods       allowMethods                   GET, POST, DELETE, *
        # Access-Control-Allow-Headers       allowHeaders                   Authorization, *

        # レスポンスヘッダー                    マッピングの値
        # Access-Control-Allow-Credentials  'true'	
        # Access-Control-Allow-Headers      'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'	
        # Access-Control-Allow-Methods      'GET,POST,OPTIONS'
        # Content-Type                      application/json

        #set($origin = $input.params().header.get('origin'))
        #if ($origin.matches("^http(s?)://(localhost|127\.0\.0\.1|.*\.pathtraq\.tagomor\.is)(:?\d+)?"))
        #  set($context.responseOverride.header.Access-Control-Allow-Origin = $origin)
        #end

        def call(event:, context:)
        end
      end

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

        @enclosure = Module.new
        @enclosure.const_set(:ENV, @env)
        path = handler.path
        begin
          ENV.mimic!(@env) do
            Kernel.load(path, @enclosure)
          end
        rescue => e
          raise "failed to load the function file '#{path}': #{e.message}"
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
