require File.expand_path('../helper', __FILE__)

class StathatTest < PapertrailServices::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_config
    svc = service(:logs, {}.with_indifferent_access, payload)
    assert_raises(PapertrailServices::Service::ConfigurationError) { svc.receive_logs }

    svc = service(:logs, {"ezkey" => "foobar"}.with_indifferent_access, payload)
    assert_raises(PapertrailServices::Service::ConfigurationError) { svc.receive_logs }

    svc = service(:logs, {"stat" => "foobar"}.with_indifferent_access, payload)
    assert_raises(PapertrailServices::Service::ConfigurationError) { svc.receive_logs }
  end

  def test_logs
    svc = service(:logs, {"ezkey" => "foo@bar.com", "stat" => "foo.bar"}.with_indifferent_access, payload)

    @stubs.get "/ez?count=5&ezkey=foo%40bar.com&stat=foo.bar" do |env|
      [200, {}, ""]
    end

    svc.receive_logs
  end

  def service(*args)
    super Service::Stathat, *args
  end
end
