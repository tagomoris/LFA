module MyApp1
  def self.process(event:, context:)
    env_foo = ENV['FOO']
    {statusCode: 200, headers: {"X-My-Header" => "Yay", "X-My-Foo" => env_foo}, body: "Foo"}
  end
end

class MyApp2Module
  def initialize
    @foo = ENV['FOO']
  end

  def process(event:, context:)
    {statusCode: 200, headers: {"X-My-Header" => "Yay", "X-My-Foo" => @foo}, body: "Foo"}
  end
end

MyApp2 = MyApp2Module.new

class MyApp3
  def self.process(event:, context:)
    query_k1 = event.dig("queryStringParameters", "key1")
    query_k2 = event.dig("queryStringParameters", "key2")
    path_p1 = event.dig("pathParameters", "p1")
    {statusCode: 200, headers: {"X-My-Key1" => query_k1, "X-My-Key2" => query_k2, "X-My-Path1" => path_p1}, body: "Bar"}
  end

  def self.process2(event:, context:)
    path_p1 = event.dig("pathParameters", "p1")
    {statusCode: 200, headers: {"X-My-Path1" => path_p1}, body: "Bar"}
  end
end
