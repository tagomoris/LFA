require 'json'

module Countries
  MESSAGE = ENV.fetch("KEY2", "yay")

  def self.process(event:, context:)
    data = ENV.fetch("KEY1", "y")
    {
      statusCode: 200,
      body: {"data" => data, "message" => MESSAGE}.to_json,
      headers: {"content-type" => "application/json"},
    }
  end
end

require_relative 'data'
