require File.expand_path('../helper.rb', __FILE__)

class HostedGraphiteTest < PapertrailServices::TestCase
  def test_config
    serv = service(:logs, {}.with_indifferent_access, counts_payload)
    assert_raises(PapertrailServices::Service::ConfigurationError) { serv.receive_counts }

    serv = service(:logs, {"api_key" => "foobar"}.with_indifferent_access,counts_payload)
    assert_raises(PapertrailServices::Service::ConfigurationError) { serv.receive_counts }

    serv = service(:logs, {"metric" => "foobar"}.with_indifferent_access,counts_payload)
    assert_raises(PapertrailServices::Service::ConfigurationError) { serv.receive_counts }

  end

  def test_logs_valid
    serv = service(:logs, {"api_key" => "foo-bar-baz", "metric" => "nice.metric.name",
                          }.with_indifferent_access,
                         counts_payload)
    http_stubs.post "/api/v1/sink" do |env|
        [200, {}, ""]
    end

    serv.receive_counts
  end

  def test_payload_empty
    serv = service(:logs, {"api_key" => "foo-bar-baz", "metric" => "nice.metric.name",
                          }.with_indifferent_access,
                          {})

    serv.receive_counts
  end

  def test_invalid_payload
    serv = service(:logs, {"api_key" => "foo-bar-baz", "metric" => "nice.metric.name",
                          }.with_indifferent_access,
                          payload)
    serv.receive_counts
  end

  def service(*args)
    super Service::HostedGraphite, *args
  end
end
