require File.expand_path('../helper', __FILE__)

class ZapierTest < PapertrailServices::TestCase

  def test_config
    svc = service(:logs, {:zapier_url => ''}, payload)
    assert_raises(PapertrailServices::Service::ConfigurationError) { svc.receive_logs }
  end

  def test_size_limit
    # This assumes the sample payload as of this writing, with a lize of 1743
    
    svc = service(:logs, {:zapier_url => 'https://zapier.com/hooks/catch/sample_url/'},
                  payload)
    limited_payload = svc.json_limited(payload, 1400)
    assert(limited_payload.length <= 1400)
  end
  
  def test_logs
    svc = service(:logs, {:zapier_url => 'https://zapier.com/hooks/catch/sample_url/'},
                  payload)

    http_stubs.post 'https://zapier.com/hooks/catch/sample_url/' do |env|
      [200, {:content_type => "application/json"}, { :status => 1 }.to_json]

      svc.receive_logs
    end
  end

  def service(*args)
    super Service::Zapier, *args
  end
  
end
