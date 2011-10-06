require File.expand_path('../helper', __FILE__)

class LibratoMetricsTest < PapertrailServices::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_logs
    svc = service(:logs, { :name => 'gauge' }, payload)

    @stubs.post '/v1/metrics.json' do |env|
      [200, {}, '']
    end

    svc.receive_logs
  end

  def test_failure
    svc = service(:logs, { :name => 'gauge' }, payload)

    @stubs.post '/v1/metrics.json' do |env|
      [400, {}, '']
    end

    assert_raise Service::ConfigurationError do
      svc.receive_logs
    end

    @stubs.post '/v1/metrics.json' do |env|
      [500, {}, 'Internal Server Error']
    end

    assert_raise Service::ConfigurationError do
      svc.receive_logs
    end
  end

  def service(*args)
    super Service::LibratoMetrics, *args
  end
end
