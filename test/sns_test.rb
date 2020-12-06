require File.expand_path('../helper', __FILE__)
ENV['STUB_RESPONSES'] = 'true'
class SNSTest < PapertrailServices::TestCase
  def test_logs
    svc = service(:logs, { :aws_access_key_id => '1', :aws_secret_access_key => '2', :aws_region => 'us-east-1', :aws_sns_topic_arn => 'arn:aws:sns:us-east-1:111111111111:pagerduty-test' }, payload)
    svc.receive_logs
  end

  def service(*args)
    super Service::SNS, *args
  end
end
