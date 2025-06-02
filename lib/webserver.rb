# frozen_string_literal: true

require 'date'
require 'erb'
require 'rack'
require 'rack/constants'
require 'rackup'
require 'uri'
require 'storage'
require 'worklog'

class DefaultHeaderMiddleware
  # Rack middleware to add default headers to the response.

  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, body = @app.call(env)
    headers[Rack::CONTENT_TYPE] ||= 'text/html'
    headers[Rack::CACHE_CONTROL] ||= 'no-cache'
    [status, headers, body]
  end
end

# Class to render the main page of the WorkLog web application.
class WorkLogResponse
  def initialize(storage, tags)
    @storage = storage
    @tags = tags
  end

  def response(request)
    template = ERB.new(File.read(File.join(File.dirname(__FILE__), 'templates', 'index.html.erb')), trim_mode: '-')
    @params = request.params
    days = @params['days'].nil? ? 7 : @params['days'].to_i
    tags = @params['tags'].nil? ? nil : @params['tags'].split(',')
    epics_only = @params['epics_only'] == 'true'
    presentation = @params['presentation'] == 'true'
    logs = @storage.days_between(Date.today - days, Date.today, epics_only, tags).reverse
    total_entries = logs.sum { |entry| entry.entries.length }
    _ = total_entries
    _ = presentation

    [200, {}, [template.result(binding)]]
  end

  private

  def update_query(new_params)
    uri = URI.parse('/')
    cloned = @params.clone
    new_params.each do |key, value|
      cloned[key] = value
    end
    uri.query = URI.encode_www_form(cloned)
    uri
  end

  def build_uri(params)
    uri = URI.parse('/')
    uri.query = URI.encode_www_form(params)
    uri.to_s
  end
end

class WorkLogApp
  def initialize(storage)
    @storage = storage
    @tags = @storage.tags
  end

  def call(env)
    req = Rack::Request.new(env)
    WorkLogResponse.new(@storage, @tags).response(req)
  end
end

# class FaviconApp
#   # Rack application that creates a favicon.

#   def self.call(_env)
#     content = ERB.new(File.read(File.join(File.dirname(__FILE__), 'templates', 'favicon.svg.erb')))
#     [200, { Rack::CONTENT_TYPE => 'image/svg+xml' }, [content.result]]
#   end
# end

class WorkLogServer
  # Main Rack server containing all endpoints.
  def initialize(worklog_app)
    @worklog_app = worklog_app
  end

  def start
    worklog_app = @worklog_app
    app = Rack::Builder.new do
      use Rack::Deflater
      use Rack::CommonLogger
      use Rack::ShowExceptions
      use Rack::ShowStatus
      use DefaultHeaderMiddleware

      map '/' do
        run worklog_app
      end
      # TODO: Future development
      # map '/favicon.svg' do
      #   run FaviconApp
      # end
    end

    Rackup::Server.start app: app
  end
end
