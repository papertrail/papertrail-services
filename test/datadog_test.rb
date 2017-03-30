require File.expand_path('../helper', __FILE__)

class DatadogTest < PapertrailServices::TestCase
  def test_config
    svc = service(:logs, {}.with_indifferent_access, payload)
    assert_raises(PapertrailServices::Service::ConfigurationError) { svc.receive_logs }

    svc = service(:logs, { 'api_key' => "foobar" }.with_indifferent_access, payload)
    assert_raises(PapertrailServices::Service::ConfigurationError) { svc.receive_logs }

    svc = service(:logs, { 'metric' => "foobar" }.with_indifferent_access, payload)
    assert_raises(PapertrailServices::Service::ConfigurationError) { svc.receive_logs }
  end

  def test_logs
    svc = service(:logs, { 'api_key' => 'foobar', "metric" => "foo.bar" }.with_indifferent_access, payload)

    http_stubs.post "/api/v1/series" do |env|

      [200, {}, ""]
    end

    svc.receive_logs
  end

  def test_tagged_logs
    svc = service(:logs, { 'api_key' => 'foobar', "metric" => "foo.bar", 'tags' => 'environment:production,sender:papertrail, severity:error ,type:NoMethodError' }.with_indifferent_access, payload)

    http_stubs.post "/api/v1/series" do |env|
      body = JSON(env[:body])

      assert body['series'][0]['tags'][0] == 'environment:production'
      assert body['series'][0]['tags'][1] == 'sender:papertrail'
      assert body['series'][0]['tags'][2] == 'severity:error'
      assert body['series'][0]['tags'][3] == 'type:NoMethodError'

      [200, {}, ""]
    end

    svc.receive_logs
  end

  def service(*args)
    super Service::Datadog, *args
  end
end
