# frozen_string_literal: true

require "test_helper"

class LFATest < Test::Unit::TestCase
  test "VERSION" do
    assert do
      ::LFA.const_defined?(:VERSION)
    end
  end

  test "something useful" do
    assert_equal("expected", "actual")
  end
end
