# frozen_string_literal: true

module LFA
  module Handler
    module Parameterized
      def stringify(value)
        case value
        when Array
          value.map(&:to_s).join(', ')
        when String
          value
        when nil
          nil
        else
          value.to_s
        end
      end
    end

    class CORSPreflight
      include Parameterized

      def initialize(params)
        @allow_origins = stringify(params[:allowOrigins])
        @mirror_allow_origin = params[:mirrorAllowOrigin]

        @allow_credentials = stringify(params[:allowCredentials])
        @allow_headers = stringify(params[:allowHeaders])
        @allow_methods = stringify(params[:allowMethods])
        @expose_headers = stringify(params[:exposeHeaders])
        @max_age = stringify(params[:maxAge])

        if @allow_origins && @mirror_allow_origin
          raise "Configuration error, allowOrigins and mirrorAllowOrigin are exclusive"
        end
      end

      def call(event:, context:)
        unless event.fetch("httpMethod") == 'OPTIONS'
          raise "CORS handler can respond to OPTIONS only, but the request is '#{event.fetch("httpMethod")}'"
        end

        # This handler ignores the preflight request headers below:
        # * Access-Control-Request-Method
        # * Access-Control-Request-Headers
        # System administrator should be able to configure this handler without use of those headers, probably.
        origin = event.dig("headers", "origin")
        {statusCode: 200, body: '', headers: cors_headers(origin)}
      end

      def cors_headers(origin)
        headers = {}
        if @allow_origins
          headers['access-control-allow-origin'] = @allow_origins
        end
        if @mirror_allow_origin
          headers['access-control-allow-origin'] = origin
          headers['vary'] = 'Origin'
        end
        if @allow_credentials
          headers['access-control-allow-credentials'] = @allow_credentials
        end
        if @allow_headers
          headers['access-control-allow-headers'] = @allow_headers
        end
        if @allow_methods
          headers['access-control-allow-methods'] = @allow_methods
        end
        if @expose_headers
          headers['access-control-expose-headers'] = @expose_headers
        end
        if @max_age
          headers['access-control-max-age'] = @max_age
        end

        headers
      end
    end
  end
end
