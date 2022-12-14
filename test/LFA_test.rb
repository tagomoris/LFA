# frozen_string_literal: true

require "test_helper"

class LFATest < Test::Unit::TestCase
  setup do
    @app = LFA.ignition!(File.join(File.dirname(__FILE__), 'app/config.yaml'))
  end

  REQUEST_TEMPLATE = {
      "REQUEST_METHOD" => "GET",
      "HTTP_VERSION" => "1.1",
      "HTTP_X_MY_HEADER1" => "MINE",
      "HTTP_X_MY_HEADER2" => "1122",
      "QUERY_STRING" => "key1=value1&key2=value2",
    }

  test 'mounted function returns a response with overridden ENV in the handler method' do
    request = REQUEST_TEMPLATE.merge({"REQUEST_PATH" => "/r1/a"})
    response = @app.call(request)
    assert_equal(200, response[0])
    assert_equal(2, response[1].size)
    assert_equal("Yay", response[1]["X-My-Header"])
    assert_equal("foowoo", response[1]["X-My-Foo"])
    assert_equal("Foo", response[2].join(''))
  end

  test 'mounted function returns a response with ENV overridden in the initialize' do
    request = REQUEST_TEMPLATE.merge({"REQUEST_PATH" => "/r1/b"})
    response = @app.call(request)
    assert_equal(200, response[0])
    assert_equal(2, response[1].size)
    assert_equal("Yay", response[1]["X-My-Header"])
    assert_equal("fwoooo", response[1]["X-My-Foo"])
    assert_equal("Foo", response[2].join(''))
  end

  test 'mounted function returns a response with the different ENV for the same function' do
    request = REQUEST_TEMPLATE.merge({"REQUEST_PATH" => "/r2/a"})
    response = @app.call(request)
    assert_equal(200, response[0])
    assert_equal(2, response[1].size)
    assert_equal("Yay", response[1]["X-My-Header"])
    assert_equal("ffoowwoo", response[1]["X-My-Foo"])
    assert_equal("Foo", response[2].join(''))
  end

  test 'mounted function returns a response with the different ENV in the initializer' do
    request = REQUEST_TEMPLATE.merge({"REQUEST_PATH" => "/r2/b"})
    response = @app.call(request)
    assert_equal(200, response[0])
    assert_equal(2, response[1].size)
    assert_equal("Yay", response[1]["X-My-Header"])
    assert_equal("fffwwwwooo", response[1]["X-My-Foo"])
    assert_equal("Foo", response[2].join(''))
  end
end
