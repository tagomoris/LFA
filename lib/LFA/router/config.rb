# frozen_string_literal: true

require 'yaml'

module LFA
  module Router
    RESOURCE_METHODS = [
      :GET, :POST, :PUT,
    ].freeze

    class Config
      attr_reader :resources, :functions

      def self.parse(yaml_filename)
        tree = File.open(yaml_filename) do |file|
          YAML.load(file.read, symbolize_names: true)
        end
        Config.new(tree)
      end

      def initialize(tree)
        # TODO: path-method-to-function cache
        raise "functions is not specified" unless tree[:functions]
        raise "resources is not specified" unless tree[:resources]
        @functions = Hash[*(tree[:functions].map{|f| Function.new(f) }.map{|f| [f.name, f] }.flatten)]
        @resources = tree[:resources].map{|r| Resource.new(r, @functions) }
      end

      PATH_PART_PATTERN = /\/[-_a-zA-Z0-9]+(.*)$/

      def dig(path, method)
        raise "invalid path" unless path.start_with?("/")
        parts = if path == "/"
                  ["/"]
                else
                  path.split("/").filter{|str| str.size > 0 }.map{|part| "/" + part}
                end
        resource = self
        parts.each do |part|
          resource = resource.resources.find{|r| r.path == part }
          break unless resource
        end
        if resource
          resource.methods[method.to_sym] # => Function
        else
          nil # when the resource is not found
        end
      end
    end

    class Resource
      attr_reader :path, :methods, :resources

      def initialize(obj, functions)
        @path = obj[:path]
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
      end
    end

    class Function
      attr_reader :name, :handler, :env

      def initialize(obj)
        raise "function name, handler are mandatory" unless obj[:name] && obj[:handler]
        @name = obj[:name]
        @handler_name = obj[:handler]
        @env = obj[:env] || {}
        @handler = Handler.parse(@handler_name)
      end

      def inspect
        "<Function name: #{@name}, handler: #{@handler}, env: #{@env}>"
      end
    end

    class Handler
      attr_reader :filename, :klass, :method

      def initialize(filename, klass, method)
        @filename = filename
        @klass = klass
        @method = method
      end

      def self.parse(name)
        filename, klass, method = name.split('.', 3)
        raise "invalid handler format '#{name}'" unless filename && klass && method
        Handler.new(filename, klass, method)
      end

      def inspect
        "<Handler #{@filename}.#{@klass}.#{@method}>"
      end
    end
  end
end
