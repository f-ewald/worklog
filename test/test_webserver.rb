# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../worklog/webserver'

class WorkLogResponseTest < Minitest::Test
  def setup
    @response = WorkLogResponse.new
  end

  def test_nil_response
    # Nil response should raise an error
    assert_raises NoMethodError do
      @response.response(nil)
    end
  end

  def test_basic_response
    params = Minitest::Mock.new.expect(:params, {})
    code, headers, content = @response.response(params)
    assert_equal 200, code
    assert_equal 'text/html', headers['Content-Type']
    assert_equal 'no-cache', headers['Cache-Control']
    assert_match(/<html>/, content[0])
  end
end
