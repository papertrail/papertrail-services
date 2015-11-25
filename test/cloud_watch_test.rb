require File.expand_path('../helper', __FILE__)
require 'aws-sdk'

class CloudWatchTest < PapertrailServices::TestCase

  def make_svc(settings)
    new_payload = payload # payload has some magic and can't be modified
    new_payload[:events].each do |e|
      # Cloudwatch demands recent dates
      e[:received_at] = (Time.now - rand(0..100)).iso8601
    end

    service(:logs,
            settings,
            new_payload)
  end

  def setup
    @common_settings = { aws_access_key_id: '123',
                         aws_secret_access_key: '456',
                         metric_namespace: "papertrail-test",
                         metric_name: "test-metric",
                         aws_region: "us-east-1"
                       }

    @svc = make_svc(@common_settings)
  end

  def test_required_settings
    settings = { aws_access_key_id: '123',
                         aws_secret_access_key: '456',
                         metric_namespace: "papertrail-test",
                         metric_name: "test-metric",
                       }
    svc = make_svc(settings)

    assert_raises(PapertrailServices::Service::ConfigurationError) {
      svc.receive_logs
    }
  end

  def test_size
    assert_raises(PapertrailServices::Service::ConfigurationError) {
      @svc.prepare_post_data(@svc.payload[:events], size_limit=8)
    }
  end

  def test_counts
    counts = @svc.event_counts_by_received_at(payload[:events])
    # Static value for counts based on current sample payload; will fail if payload is changed
    assert_equal(counts, {1311369001=>1, 1311369010=>1, 1311370201=>1, 1311370801=>1, 1311371401=>1})
  end

  def test_logs
    AWS.stub!
    @svc.receive_logs
  end

  def service(*args)
    super Service::CloudWatch, *args
  end
end
