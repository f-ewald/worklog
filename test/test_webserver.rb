# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../worklog/webserver'

class DefaultHeaderMiddlewareTest < Minitest::Test
  def setup
    @app = Object.new
    def @app.call(env)
      [200, {}, ['Hello, World!']]
    end
    @middleware = DefaultHeaderMiddleware.new(@app)
  end

  def test_default_headers
    status, headers, content = @middleware.call({})
    assert_equal 200, status
    assert_equal 'text/html', headers['Content-Type']
    assert_equal 'no-cache', headers['Cache-Control']
    assert_equal 'Hello, World!', content[0]
  end
end

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
    # No custom headers expected as they're added through middleware.
    assert_equal 0, headers.length
    assert_match(/<html>/, content[0])
  end
end
