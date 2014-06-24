require File.expand_path('../helper', __FILE__)

class SNSTest < PapertrailServices::TestCase
  def setup
    AWS.stub!
  end

  def test_logs_no_incident_id
    svc = service(:logs, { :aws_access_key_id => '1', :aws_secret_access_key => '2', :aws_region => '3', :aws_sns_topic_arn => 'arn:aws:sns:us-west-1:111111111111:papertrail-test' }, payload)
    svc.receive_logs
  end

  def test_logs_with_incident_id
    svc = service(:logs, { :aws_access_key_id => '1', :aws_secret_access_key => '2', :aws_region => '3', :aws_sns_topic_arn => 'arn:aws:sns:us-west-1:111111111111:papertrail-test', :aws_sns_incident_id => 'test-id' }, payload)
    svc.receive_logs
  end

  def test_no_access_id
    svc = service(:logs, { :aws_secret_access_key => '2', :aws_region => '3', :aws_sns_topic_arn => 'arn:aws:sns:us-west-1:111111111111:papertrail-test' }, payload)
    assert_raises(PapertrailServices::Service::ConfigurationError) { svc.receive_logs }
  end

  def test_no_secret_access_key
    svc = service(:logs, { :aws_access_key_id => '1', :aws_region => '3', :aws_sns_topic_arn => 'arn:aws:sns:us-west-1:111111111111:papertrail-test' }, payload)
    assert_raises(PapertrailServices::Service::ConfigurationError) { svc.receive_logs }
  end

  def test_no_region
    svc = service(:logs, { :aws_access_key_id => '1', :aws_secret_access_key => '2', :aws_sns_topic_arn => 'arn:aws:sns:us-west-1:111111111111:papertrail-test' }, payload)
    assert_raises(PapertrailServices::Service::ConfigurationError) { svc.receive_logs }
  end

  def test_no_arn
    svc = service(:logs, { :aws_access_key_id => '1', :aws_secret_access_key => '2', :aws_region => '3' }, payload)
    assert_raises(PapertrailServices::Service::ConfigurationError) { svc.receive_logs }
  end

  def service(*args)
    super Service::SNS, *args
  end
end
