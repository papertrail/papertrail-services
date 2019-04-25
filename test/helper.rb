require 'minitest/autorun'
require File.expand_path('../../config/bootstrap.rb', __FILE__)

require 'mocha/setup'

class PapertrailServices::TestCase < Minitest::Test
  def test_default
  end

  def service(klass, event_or_data, data, payload=nil)
    event = nil
    if event_or_data.is_a?(Symbol)
      event = event_or_data
    else
      payload = data
      data    = event_or_data
      event   = :logs
    end

    service = klass.new(event, data, payload)
    service.http = Faraday.new do |b|
      b.adapter :test, http_stubs
    end
    service
  end

  def basic_auth(user, pass)
    "Basic " + ["#{user}:#{pass}"].pack("m*").strip
  end

  def payload
    PapertrailServices::Helpers::LogsHelpers.sample_payload
  end

  def counts_payload
    PapertrailServices::Helpers::LogsHelpers.sample_counts_payload
  end

  def http_stubs
    @http_stubs ||= Faraday::Adapter::Test::Stubs.new
  end
end
