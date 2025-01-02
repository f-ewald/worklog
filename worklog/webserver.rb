# frozen_string_literal: true

require 'date'
require 'erb'
require 'rack'
require 'rackup'
require 'uri'
require 'storage'
require 'worklog'



class WorkLogResponse
  def response(request)
    template = ERB.new(File.read(File.join(File.dirname(__FILE__),'index.html.erb')), trim_mode: '-')
    @params = request.params
    days = @params['days'].nil? ? 7 : @params['days'].to_i
    # since = params['since'].nil? ? Date.today - 7 : Date.parse(params['since'])
    tags = @params['tags'].nil? ? nil : @params['tags'].split(',')
    epics_only = @params['epics_only'] == 'true'
    presentation = @params['presentation'] == 'true'
    logs = Storage::days_between(Date.today - days, Date.today, epics_only, tags).reverse
    total_entries = logs.sum { |entry| entry.entries.length }
    _ = total_entries
    _ = presentation

    [ 200, {
      "Content-Type" => "text/html",
      "Cache-Control" => "no-cache",
    }, [ template.result(binding) ] ]
  end

  private

  # Update query by overwriting existing query params.
  def update_query(new_params)
    uri = URI.parse("/")
    # cloned = existing_params.clone
    cloned = @params.clone
    new_params.each do |key, value|
      cloned[key] = value
    end
    uri.query = URI.encode_www_form(cloned)
    uri
  end

  def build_uri(params)
    uri = URI.parse("/")
    uri.query = URI.encode_www_form(params)
    uri.to_s
  end
end


# Rack application.
class WorkLogApp
  def self.call(env)
    # Extract the request and pass to method.
    req = Rack::Request.new(env)
    WorkLogResponse.new.response(req)
  end
end

class WorkLogServer
  # Start the server.
  def start
    Rackup::Server.start :app => WorkLogApp
  end
end
