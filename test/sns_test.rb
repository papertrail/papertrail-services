require File.expand_path('../helper', __FILE__)

class SNSTest < PapertrailServices::TestCase
  def setup
    AWS.stub!
  end

  def test_logs
    svc = service(:logs, { :aws_access_key_id => '1', :aws_secret_access_key => '2', :aws_region => '3', :aws_sns_topic_arn => 'arn:aws:sns:us-west-1:111111111111:pagerduty-test' }, payload)
    svc.receive_logs
  end

  def service(*args)
    super Service::SNS, *args
  end
end
