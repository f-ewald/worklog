# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../worklog/webserver'

# class TemplateHelpersTest < Minitest::Test
#   def setup
#     @helpers = Object.new
#     def @helpers.params
#       {}
#     end
#     @helpers.extend(TemplateHelpers)
#   end

#   def test_update_query
#     assert @helpers.params.is_a? Hash
#     uri = @helpers.update_query({ days: 7 })
#     assert_equal '/?days=7', uri.to_s
#   end

#   def test_build_uri
#     uri = @helpers.build_uri({ 'days' => 7 })
#     assert_equal '/?days=7', uri
#   end
# end

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
