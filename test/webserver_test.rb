# frozen_string_literal: true

require_relative 'test_helper'
require 'minitest/autorun'
require 'configuration'
require 'storage'
require 'webserver'

class DefaultHeaderMiddlewareTest < Minitest::Test
  def setup
    @app = Object.new
    def @app.call(env)
      [200, {}, ['Hello, World!']]
    end
    @middleware = DefaultHeaderMiddleware.new(@app)

    @storage = storage_helper
  end

  def test_default_headers
    status, headers, content = @middleware.call({})
    assert_equal 200, status
    assert_equal 'text/html', headers[Rack::CONTENT_TYPE]
    assert_equal 'no-cache', headers[Rack::CACHE_CONTROL]
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
    config = configuration_helper
    @storage = Storage.new(config)
    @response = WorkLogResponse.new @storage, {}
  end

  def test_nil_response
    # Nil response should raise an error
    assert_raises NoMethodError do
      @response.response(nil)
    end
  end

  def test_basic_response
    refute_nil @response

    params = Minitest::Mock.new.expect(:params, {})
    code, headers, content = @response.response(params)
    assert_equal 200, code
    # No custom headers expected as they're added through middleware.
    assert_equal 0, headers.length
    assert_match(/<html>/, content[0])
  end
end
