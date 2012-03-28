require File.expand_path('../helper', __FILE__)

class GeckoBoardTest < PapertrailServices::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_logs
    svc = service(:logs, { :token => 'abc', :widget_key => 'def' }, payload)

    @stubs.post '/v1/send/abc' do |env|
      [200, {}, '']
    end

    svc.receive_logs
  end

  def test_failure
    svc = service(:logs, { :token => 'abc', :widget_key => 'def' }, payload)

    @stubs.post '/v1/send/abc' do |env|
      [400, {}, '{ "error":"Bad juju" }']
    end

    assert_raise Service::ConfigurationError do
      svc.receive_logs
    end

    @stubs.post '/v1/send/abc' do |env|
      [500, {}, 'Internal Server Error']
    end

    assert_raise Service::ConfigurationError do
      svc.receive_logs
    end
  end

  def service(*args)
    super Service::GeckoBoard, *args
  end
end
