require File.expand_path('../helper', __FILE__)

class LibratoMetricsTest < PapertrailServices::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_logs
    Librato::Metrics::Queue.any_instance.expects(:submit)

    svc = service(:logs, { :name => 'gauge', :user => 'a@b.com', :token => 'abc' }, shifted_payload)

    @stubs.post '/v1/metrics.json' do |env|
      [200, {}, '']
    end

    svc.receive_logs
  end


  def test_unauthorized
    Librato::Metrics::Queue.any_instance.expects(:submit).raises(Librato::Metrics::Unauthorized)

    svc = service(:logs, { :name => 'gauge', :user => 'a@b.com', :token => 'abc' }, shifted_payload)

    assert_raise Service::ConfigurationError do
      svc.receive_logs
    end
  end

  def test_error
    Librato::Metrics::Queue.any_instance.expects(:submit).raises(Librato::Metrics::MetricsError)

    svc = service(:logs, { :name => 'gauge', :user => 'a@b.com', :token => 'abc' }, shifted_payload)

    assert_raise Service::ConfigurationError do
      svc.receive_logs
    end
  end

  # Shift time stamps to within the acceptable offset from
  # real time. This should try to keep the uniqueness of times
  # whenever possible (except when a factor of the max offset).
  def shifted_payload
    now = Time.now.tv_sec
    max_real_offset = 3600 * 24

    spayload = payload.dup
    spayload[:events].each do |event|
      time = Time.parse(event[:received_at])
      time = time.to_i - (time.to_i % 60)
      delta = now - time
      event[:received_at] = Time.at(now - (delta % max_real_offset)).to_s
    end

    spayload
  end

  def service(*args)
    super Service::LibratoMetrics, *args
  end
end
