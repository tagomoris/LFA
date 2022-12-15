require "json"

module Data
  def self.process(event:, context:)
    data_type = ENV.fetch("OUTPUT_DATA_TYPE", "txt")
    case data_type
    when "json"
      {
        statusCode: 200,
        body: {"data" => "boo", "message" => "foo"}.to_json,
        headers: {"content-type" => "application/json"},
      }
    when "csv"
      {
        statusCode: 200,
        body: "data,yaaaay",
        headers: {"content-type" => "text/csv"},
      }
    else
      {
        statusCode: 200,
        body: "data. yaaaaay!",
        headers: {"content-type" => "text/plain"},
      }
    end
  end
end
