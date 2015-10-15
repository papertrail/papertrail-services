require File.expand_path('../helper', __FILE__)

class PushoverTest < PapertrailServices::TestCase

  def test_config
    svc = service(:logs, {:token => 'a sample token'}, payload)
    assert_raises(PapertrailServices::Service::ConfigurationError) { svc.receive_logs }

    svc = service(:logs, {:user_key => 'a different token'}, payload)
    assert_raises(PapertrailServices::Service::ConfigurationError) { svc.receive_logs }
  end
  
  def test_logs
    svc = service(:logs, {:token => 'a sample token',
                          :user_key => 'a different token'},
                  payload)

    http_stubs.post '/1/messages.json' do |env|
      [200, {:content_type => "application/json"}, { :status => 1 }.to_json]

      svc.receive_logs
    end



  end

  def service(*args)
    super Service::Pushover, *args
  end
  
end
