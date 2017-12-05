require File.expand_path('../helper', __FILE__)

class AppOpticsTest < PapertrailServices::TestCase
  def test_removes_spaces_from_metric_name
    service = service(:logs, { :name  => 'very  wordy metric' }, payload)
    assert_equal 'very_wordy_metric', service.metric_name
  end

  def test_handles_nil_appoptics_token
    service = service(:logs, {}, payload)
    assert_equal '', service.appoptics_token
  end

  def test_cleans_whitespace_from_appoptics_token
    service = service(:logs, { :token  => ' towel  ' }, payload)
    assert_equal 'towel', service.appoptics_token
  end

  def test_submits_logs_metrics
    expected_metrics = { 'alien'   => { 1311369000 => 2,
                                        1311370200 => 1,
                                        1311370800 => 1 },
                         'lullaby' => { 1311371400 => 1 }}

    service = service(:logs, service_settings, payload)
    service.expects(:submit_metrics).with(expected_metrics)
    service.receive_logs
  end

  def test_submits_counts_metrics
    expected_metrics = { 'alien'   => { 1311369000 => 2,
                                        1311370200 => 1,
                                        1311370800 => 1 },
                         'lullaby' => { 1311371400 => 1 }}

    service = service(:logs, service_settings, counts_payload)
    service.expects(:submit_metrics).with(expected_metrics)
    service.receive_counts
  end

  def test_submitting_metrics
    AppOptics::Metrics::Queue.any_instance.expects(:submit)

    metrics = { 'alien' => { Time.now.to_i => 2 }}
    service(:logs, service_settings, counts_payload).submit_metrics(metrics)
  end

  def test_submitting_no_metrics_sends_nothing
    AppOptics::Metrics::Queue.any_instance.expects(:submit).never

    metrics = {}
    service(:logs, service_settings, counts_payload).submit_metrics(metrics)
  end

  def test_submitting_no_measurements_sends_nothing
    AppOptics::Metrics::Queue.any_instance.expects(:submit).never

    metrics = { 'alien' => {}}
    service(:logs, service_settings, counts_payload).submit_metrics(metrics)
  end

  def test_submitting_metrics_unauthorized
    AppOptics::Metrics::Queue.any_instance.expects(:submit)
      .raises(AppOptics::Metrics::Unauthorized.new('unauthorized'))

    metrics = { 'alien' => { Time.now.to_i => 2 }}
    assert_raise Service::ConfigurationError do
      service(:logs, service_settings, counts_payload).submit_metrics(metrics)
    end
  end

  def test_submitting_metrics_error
    AppOptics::Metrics::Queue.any_instance.expects(:submit)
      .raises(AppOptics::Metrics::MetricsError)

    metrics = { 'alien' => { Time.now.to_i => 2 }}
    assert_raise Service::ConfigurationError do
      service(:logs, service_settings, counts_payload).submit_metrics(metrics)
    end
  end

  def service(*args)
    super Service::AppOptics, *args
  end

  def service_settings
    { :name  => 'gauge',
      :token => 'towel' }
  end
end
