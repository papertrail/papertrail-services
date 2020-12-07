require File.expand_path('../helper.rb', __FILE__)
# ENV['STUB_RESPONSES'] = 'true'
class CloudWatchTest < PapertrailServices::TestCase

  def setup
    @common_settings = { aws_access_key_id: '123',
                         aws_secret_access_key: '456',
                         metric_namespace: "papertrail-test",
                         metric_name: "test-metric",
                         aws_region: "us-east-1"
                       }
    new_payload = payload # payload has some magic and can't be modified
    new_payload[:events].each do |e|
      # Cloudwatch demands recent dates
      e[:received_at] = (Time.now - rand(0..100)).iso8601
    end

    @svc = service(:logs,
                   @common_settings,
                   new_payload)
  end

  def test_counts
    counts = @svc.event_counts_by_received_at(payload[:events])
    # Static value for counts based on current sample payload; will fail if payload is changed
    assert_equal(counts, {1311369001=>1, 1311369010=>1, 1311370201=>1, 1311370801=>1, 1311371401=>1})
  end

  def test_logs
    @svc.receive_logs
  end

  def service(*args)
    super Service::CloudWatch, *args
  end
end
