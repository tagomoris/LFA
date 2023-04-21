# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "LFA"

require "test-unit"

def read_body(body)
  str = String.new
  body.each{|s| str << s }
  str
end
