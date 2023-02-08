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

module City
  # "resource"=>"/api/place/{place_id}", "path"=>"/api/place/tokyo", "pathParameters"=>{"place_id"=>"tokyo"}
  def self.process(event:, context:)
    city_name = event.dig("pathParameters", "place_id")
    {
      statusCode: 200,
      body: {"city_name" => city_name, "message" => "good city!"}.to_json,
      headers: {"content-type" => "application/json"},
    }
  end
end

module Town
  # "resource"=>"/api/town/{names+}", "path"=>"/api/checkin/yay1", "pathParameters"=>{"names"=>"yay1"}
  # "resource"=>"/api/town/{names+}", "path"=>"/api/checkin/yay1/foo2/bar3", "pathParameters"=>{"names"=>"yay1/foo2/bar3"},
  def self.process(event:, context:)
    towns = event.dig("pathParameters", "names").split("/")
    {
      statusCode: 200,
      body: {"towns" => towns, "message" => "good towns!"}.to_json,
      headers: {"content-type" => "application/json"},
    }
  end
end
