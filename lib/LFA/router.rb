# frozen_string_literal: true

require_relative './router/config'

module LFA
  module Router
    def self.resolver(config_filename)
      config = Config.parse(config_filename)
      return Resolver.new(config)
    end

    class Resolver
      def initialize(config)
        @config = config
        @cache = {}
      end

      def resolve(path, method)
        cache_key = "#{method}\t#{path}"
        return @cache[cache_key] if @cache.has_key?(cache_key) # return stored nil when the cache key exists

        matched = @config.dig(path, method)
        @cache[cache_key] = matched # store negative cache to not pay too much cost for 404 even when nil (404)
        matched
      end
    end
  end
end
