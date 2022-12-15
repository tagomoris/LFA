# frozen_string_literal: true

require_relative "LFA/version"
require_relative "LFA/router"
require_relative "LFA/adapter"

module LFA
  def self.ignition!(config_filename)
    router = Router.resolver(config_filename)
    return Adapter.new(router)
  end
end
