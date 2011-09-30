require File.expand_path('../helper', __FILE__)

class CloudWatchTest < PapertrailServices::TestCase
  class MockAcwInterface      
    def put_metric_data(options)
      options[:data_points] ? true : false
    end    
  end
  
  def setup
    @common_settings = { :aws_access_key_id => '123', :aws_secret_access_key => '456' }
  end

  def test_logs
    svc = service(:logs, 
      metric_regex_params(3, :dimension => 'Region=West;Element=page').merge(@common_settings), 
      payload)
    
    svc.acw = MockAcwInterface.new

    svc.receive_logs
  end

  def service(*args)
    super Service::CloudWatch, *args
  end
  
  def metric_regex_params(count, metric_options = { :regex => 'abc' })
    metrics = {}
    count.times.map do |i|
      metrics[i] = { :name => "MetricName#{i}" }
      metrics[i].merge!(metric_options)
    end
    { :metric => metrics }
  end
end