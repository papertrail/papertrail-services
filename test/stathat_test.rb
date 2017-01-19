require File.expand_path('../helper', __FILE__)

class StathatTest < PapertrailServices::TestCase
  def test_config
    svc = service(:logs, {}.with_indifferent_access, counts_payload)
    assert_raises(PapertrailServices::Service::ConfigurationError) { svc.receive_counts }

    svc = service(:logs, {"ezkey" => "foobar"}.with_indifferent_access, counts_payload)
    assert_raises(PapertrailServices::Service::ConfigurationError) { svc.receive_counts }

    svc = service(:logs, {"stat" => "foobar"}.with_indifferent_access, counts_payload)
    assert_raises(PapertrailServices::Service::ConfigurationError) { svc.receive_counts }
  end

  def test_logs
    svc = service(:logs, {"ezkey" => "foo@bar.com", "stat" => "foo.bar"}.with_indifferent_access, payload)

    http_stubs.post "/ez" do |env|
      [200, {}, ""]
    end

    svc.receive_logs
  end

  def test_counts
    svc = service(:counts, {"ezkey" => "foo@bar.com", "stat" => "foo.bar"}.with_indifferent_access, counts_payload)

    http_stubs.post "/ez" do |env|
      [200, {}, ""]
    end

    svc.receive_counts
  end

  def test_counts_payload_to_metrics
    svc = service(:counts, {"ezkey" => "foo@bar.com", "stat" => "foo.bar"}.with_indifferent_access, counts_payload)
    expected = [
      { stat: "foo.bar", count: 1, t: 1311369001 },
      { stat: "foo.bar", count: 1, t: 1311369010 },
      { stat: "foo.bar", count: 1, t: 1311370201 },
      { stat: "foo.bar", count: 1, t: 1311370801 },
      { stat: "foo.bar", count: 1, t: 1311371401 }
    ]

    assert_equal expected, svc.counts_payload_to_metrics
  end

  def service(*args)
    super Service::Stathat, *args
  end
end
