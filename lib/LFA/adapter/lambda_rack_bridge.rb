# frozen_string_literal: true

require 'securerandom'
require 'cgi'

module LFA
  class Adapter
    module LambdaRackBridge
      def request_path(env:)
        env["REQUEST_PATH"]
      end

      def http_method(env:)
        env["REQUEST_METHOD"]
      end

      def lambda_event(env:, path_parameters:)
        headers, mv_headers = build_headers(env)
        query_params, mv_query_params = build_query_params(env)
        {
          "resource"   => env["REQUEST_PATH"],
          "path"       => env["REQUEST_PATH"],
          "httpMethod" => env["REQUEST_METHOD"],
          "headers"           => headers,
          "multiValueHeaders" => mv_headers,
          "queryStringParameters"           => query_params,
          "multiValueQueryStringParameters" => mv_query_params,
          "pathParameters" => path_parameters, # set when path parameters are supported
          "stageVariables" => nil, # LFA will not support deployments on stages
          "requestContext" => {},  # skipped for now because it seems not useful...
          "body" => env["rack.input"],
          "isBase64Encoded" => false, # always false about request? true if the request was binary?
        }
      end

      def lambda_context(function_name:)
        LambdaContext.new(function_name)
      end

      def convert_to_rack_response(resp)
        ### Lambda output
        # {
        #   statusCode: 200,
        #   body: records.to_json,
        #   headers: {"content-type" => "application/json"},
        # }
        ### Rack response
        # [200, {"content-type" => "application/json"}, [body]]

        [resp[:statusCode], resp[:headers], [resp[:body]]]
      end


      def build_headers(env)
        headers = Headers.new
        multi_value_headers = Headers.new
        env.keys.each do |env_key_name|
          next unless env_key_name =~ /^HTTP_/
          next if env_key_name == 'HTTP_VERSION'
          header_name = header_name_from_env_name(env_key_name)
          value = env[env_key_name]
          if value.include?(", ")
            multi_value_headers[header_name] = value.split(", ").select{|s| !s.empty? }.compact
            headers[header_name] = value.split(", ").select{|s| !s.empty? }.compact.last
          else
            multi_value_headers[header_name] = [value]
            headers[header_name] = value
          end
        end
        return headers, multi_value_headers
      end

      def build_query_params(env)
        query = env["QUERY_STRING"]
        return nil, nil if !query || query.empty?

        multi_value_query_params = CGI.parse(query)
        query_params = {}
        multi_value_query_params.each do |key, value|
          query_params[key] = value.last
        end
        return query_params, multi_value_query_params
      end

      def header_name_from_env_name(name)
        name.sub('HTTP_', '').gsub('_', '-').downcase
      end

      class Headers < Hash
        def [](key)
          super(key.downcase)
        end

        def []=(key, value)
          super(key.downcase, value)
        end

        def has_key?(key)
          super(key.downcase)
        end
      end

      class LambdaContext
        # Lambda Context https://docs.aws.amazon.com/lambda/latest/dg/ruby-context.html
        # Context methods
        # # get_remaining_time_in_millis – Returns the number of milliseconds left before the execution times out.
        # Context properties
        # # function_name – The name of the Lambda function.
        # # function_version – The version of the function.
        # # invoked_function_arn – The Amazon Resource Name (ARN) that's used to invoke the function.
        # #                        Indicates if the invoker specified a version number or alias.
        # # memory_limit_in_mb – The amount of memory that's allocated for the function.
        # # aws_request_id – The identifier of the invocation request.
        # # log_group_name – The log group for the function.
        # # log_stream_name – The log stream for the function instance.
        # # deadline_ms– The date that the execution times out, in Unix time milliseconds.
        # # identity – (mobile apps) Information about the Amazon Cognito identity that authorized the request.
        # # client_context– (mobile apps) Client context that's provided to Lambda by the client application.

        attr_reader :function_name, :function_version, :invoked_function_arn, :memory_limit_in_mb
        attr_reader :aws_request_id, :log_group_name, :log_stream_name, :deadline_ms, :identity, :client_context

        def initialize(function_name)
          @function_name = function_name
          @function_version = 1
          @invoked_function_arn = "arn:tagomoris:lambda:ap-northeast-999:0000000000000:function:#{function_name}"
          @memory_limit_in_mb = 1024 # TODO: configurable?
          @aws_request_id = SecureRandom.uuid
          @log_group_name = "/tagomoris/lambda/#{function_name}"
          @log_stream_name = "2022/12/15[$LATEST]0000000000000000000000"
          @deadline_ms = 3600 * 1000
          @identity = nil
          @client_context = nil
        end

        def get_remaining_time_in_millis
          3600 * 1000
        end
      end

      # Rack ENV
      # {
      #   "rack.version"=>[1, 6],
      #   "rack.errors"=>obj,#<Rack::Lint::Wrapper::ErrorWrapper:0x0000000107036620 @error=#<IO:<STDERR>>>,
      #   "rack.multithread"=>true,
      #   "rack.multiprocess"=>false,
      #   "rack.run_once"=>false,
      #   "rack.url_scheme"=>"http",
      #   "SCRIPT_NAME"=>"",
      #   "QUERY_STRING"=>"key=value",
      #   "SERVER_SOFTWARE"=>"puma 6.0.0 Sunflower",
      #   "GATEWAY_INTERFACE"=>"CGI/1.2",
      #   "REQUEST_METHOD"=>"GET",
      #   "REQUEST_PATH"=>"/api/language",
      #   "REQUEST_URI"=>"/api/language?key=value",
      #   "SERVER_PROTOCOL"=>"HTTP/1.1",
      #   "HTTP_HOST"=>"127.0.0.1:9292",
      #   "HTTP_USER_AGENT"=>"curl/7.79.1",
      #   "HTTP_ACCEPT"=>"*/*",
      #   "HTTP_X_YAY"=>"one, two", # Multi value headers
      #   "puma.request_body_wait"=>0.010000228881835938,
      #   "SERVER_NAME"=>"127.0.0.1",
      #   "SERVER_PORT"=>"9292",
      #   "PATH_INFO"=>"/api/language",
      #   "REMOTE_ADDR"=>"127.0.0.1",
      #   "HTTP_VERSION"=>"HTTP/1.1",
      #   "puma.socket"=>obj,#<TCPSocket:fd 16, AF_INET, 127.0.0.1, 9292>,
      #   "rack.hijack?"=>true,
      #   "rack.hijack"=>obj,#<Proc:0x0000000107036a30 /versions/3.1.0/lib/ruby/gems/3.1.0/gems/rack-3.0.2/lib/rack/lint.rb:556>,
      #   "rack.input"=>obj,#<Rack::Lint::Wrapper::InputWrapper:0x0000000107036710 @input=#<Puma::NullIO:0x0000000106fb4b48>>,
      #   "rack.after_reply"=>[],
      #   "puma.config"=>obj,
      #   "rack.tempfiles"=>[],
      # }

      # Lambda Event
      # {
      #   "resource"=>"/api/raw_data",
      #   "path"=>"/api/raw_data",
      #   "httpMethod"=>"GET",
      #   "headers"=>{
      #     "accept"=>"*/*", "Host"=>"1jlbwglsci.execute-api.ap-northeast-1.amazonaws.com",
      #     "User-Agent"=>"curl/7.77.0", "X-Amzn-Trace-Id"=>"Root=1-61d5681d-2f0156ce0aeee3896ab2cf1f",
      #     "X-Forwarded-For"=>"138.64.70.55", "X-Forwarded-Port"=>"443", "X-Forwarded-Proto"=>"https",
      #     "x-pathtraq-apikey"=>"711e31a7-5248-45bc-92b8-c39740842a5f"
      #   },
      #   "multiValueHeaders"=>{
      #     "accept"=>["*/*"], "Host"=>["1jlbwglsci.execute-api.ap-northeast-1.amazonaws.com"],
      #     "User-Agent"=>["curl/7.77.0"], "X-Amzn-Trace-Id"=>["Root=1-61d5681d-2f0156ce0aeee3896ab2cf1f"],
      #     "X-Forwarded-For"=>["138.64.70.55"], "X-Forwarded-Port"=>["443"], "X-Forwarded-Proto"=>["https"],
      #     "x-pathtraq-apikey"=>["711e31a7-5248-45bc-92b8-c39740842a5f"]
      #   },
      #   "queryStringParameters"=>nil,
      #   "multiValueQueryStringParameters"=>nil,
      #   "pathParameters"=>nil,
      #   "stageVariables"=>nil,
      #   "requestContext"=>{
      #     "resourceId"=>"541ciq", "resourcePath"=>"/api/raw_data",
      #     "httpMethod"=>"GET", "extendedRequestId"=>"Ld00sEvoNjMF8Zg=",
      #     "requestTime"=>"05/Jan/2022:09:42:53 +0000",
      #     "path"=>"/test/api/raw_data", "accountId"=>"752037627773",
      #     "protocol"=>"HTTP/1.1", "stage"=>"test", "domainPrefix"=>"1jlbwglsci",
      #     "requestTimeEpoch"=>1641375773896, "requestId"=>"32d4b1da-ba45-4758-a2db-467194ffca11",
      #     "identity"=>{
      #       "cognitoIdentityPoolId"=>nil, "accountId"=>nil, "cognitoIdentityId"=>nil, "caller"=>nil,
      #       "sourceIp"=>"138.64.70.55", "principalOrgId"=>nil, "accessKey"=>nil,
      #       "cognitoAuthenticationType"=>nil, "cognitoAuthenticationProvider"=>nil, "userArn"=>nil,
      #       "userAgent"=>"curl/7.77.0", "user"=>nil
      #     },
      #     "domainName"=>"1jlbwglsci.execute-api.ap-northeast-1.amazonaws.com",
      #     "apiId"=>"1jlbwglsci"
      #   },
      #   "body"=>nil,
      #   "isBase64Encoded"=>false
      # }

      # Lambda Context https://docs.aws.amazon.com/lambda/latest/dg/ruby-context.html
      # Context methods
      # # get_remaining_time_in_millis – Returns the number of milliseconds left before the execution times out.
      # Context properties
      # # function_name – The name of the Lambda function.
      # # function_version – The version of the function.
      # # invoked_function_arn – The Amazon Resource Name (ARN) that's used to invoke the function.
      # #                        Indicates if the invoker specified a version number or alias.
      # # memory_limit_in_mb – The amount of memory that's allocated for the function.
      # # aws_request_id – The identifier of the invocation request.
      # # log_group_name – The log group for the function.
      # # log_stream_name – The log stream for the function instance.
      # # deadline_ms– The date that the execution times out, in Unix time milliseconds.
      # # identity – (mobile apps) Information about the Amazon Cognito identity that authorized the request.
      # # client_context– (mobile apps) Client context that's provided to Lambda by the client application.
    end
  end
end
