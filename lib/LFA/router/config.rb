# frozen_string_literal: true

require 'yaml'

module LFA
  module Router
    RESOURCE_METHODS = [
      :GET, :POST, :PUT, :OPTIONS, :ANY,
    ].freeze

    class Config
      attr_reader :resources, :functions

      def self.parse(yaml_filename)
        tree = File.open(yaml_filename) do |file|
          YAML.load(file.read, symbolize_names: true, aliases: true)
        end
        dirname = File.dirname(File.absolute_path(yaml_filename))
        Config.new(tree, dirname)
      end

      def initialize(tree, dirname)
        # TODO: path-method-to-function cache
        raise "functions is not specified" unless tree[:functions]
        raise "resources is not specified" unless tree[:resources]
        @functions = Hash[*(tree[:functions].map{|f| Function.new(f, dirname) }.map{|f| [f.name, f] }.flatten)]
        @resources = tree[:resources].map{|r| Resource.new(r, @functions) }
      end

      def dig(path, method)
        raise "invalid path" unless path.start_with?("/")
        parts = if path == "/"
                  ["/"]
                else
                  path.split("/").filter{|str| str.size > 0 }.map{|part| "/" + part}
                end
        resource = self
        path_parameters = {}
        parts.each_with_index do |part, index|
          resource = resource.resources.find{|r| r.is_wildcard? || r.path == part }
          if resource
            if resource.is_wildcard? && resource.is_greedy_wildcard?
              path_parameters[resource.parameter_name] = (parts[index..-1].join)[1..-1] # omit heading '/'
              break
            elsif resource.is_wildcard?
              path_parameters[resource.parameter_name] = part[1..-1] # omit heading '/'
            end
          else # resource == nil
            break
          end
        end
        if resource
          if resource.is_greedy_wildcard?
            MatchedFunction.new(
              function: resource.methods.fetch(:ANY),
              path_parameters: path_parameters,
            )
          else
            func = resource.methods[method.to_sym]
            if func
              MatchedFunction.new(
                function: func,
                path_parameters: path_parameters.size > 0 ? path_parameters : nil,
              )
            else
              nil
            end
          end
        else
          nil # when the resource is not found
        end
      end
    end

    MatchedFunction = Data.define(:function, :path_parameters)

    class Resource
      attr_reader :path, :parameter_name, :methods, :resources

      def initialize(obj, functions)
        @path = obj[:path]
        raise "path must start with '/'" unless @path.start_with?('/')
        @methods_hash = obj[:methods] || []
        @resources_array = obj[:resources] || []
        @methods = {}
        @methods_hash.each do |method_name, function_name|
          raise "unsupported method '#{method_name}'" unless RESOURCE_METHODS.include?(method_name)
          raise "function name missing '#{function_name}'" unless functions.has_key?(function_name)
          raise "duplicated config on method '#{method_name}'" if @methods[method_name]
          @methods[method_name] = functions[function_name]
        end
        @resources = @resources_array.map{|resource_obj| Resource.new(resource_obj, functions) }

        @parameter_name = nil
        @greedy_match = nil
        if @path.start_with?('/{') && @path.end_with?('}')
          if @path.end_with?('+}')
            @parameter_name = @path[2..-3]
            @greedy_match = true
          else
            @parameter_name = @path[2..-2]
            @greedy_match = false
          end
        end
        if @greedy_match.!.! && @methods.keys != [:ANY]
          raise "resource with a greedy path parameter '{part+}' must respond to only ANY method"
        end
      end

      def is_wildcard?
        @parameter_name != nil
      end

      def is_greedy_wildcard?
        @greedy_match.!.!
      end
    end

    class Function
      attr_reader :name, :handler, :env, :params, :dirname

      def initialize(obj, dirname)
        raise "function name, handler are mandatory" unless obj[:name] && obj[:handler]
        @name = obj[:name]
        @handler_name = obj[:handler]
        @env = obj[:env] || {}
        @params = obj[:params] || {}
        @handler = if @handler_name =~ /\A[A-Z0-9_]+\z/
                     BuiltInHandler.new(@handler_name)
                   else
                     Handler.parse(@handler_name, dirname)
                   end
      end

      def inspect
        "<Function name: #{@name}, handler: #{@handler}, env: #{@env}, params: #{@params}>"
      end
    end

    class BuiltInHandler
      attr_reader :name

      def initialize(handler_name)
        @name = handler_name
      end

      def builtin?
        true
      end

      def inspect
        "<BuiltInHandler #{@name}>"
      end
    end

    class Handler
      attr_reader :filename, :klass, :method

      def initialize(filename, klass, method, dirname)
        @filename = filename
        @klass = klass
        @method = method
        @dirname = dirname
      end

      def self.parse(name, dirname)
        filename, klass, method = name.split('.', 3)
        raise "invalid handler format '#{name}'" unless filename && klass && method
        Handler.new(filename, klass, method, dirname)
      end

      def builtin?
        false
      end

      def inspect
        "<Handler #{@filename}.#{@klass}.#{@method}>"
      end

      def path
        File.join(@dirname, @filename + '.rb')
      end
    end
  end
end
