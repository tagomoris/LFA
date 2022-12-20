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
