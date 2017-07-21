require File.expand_path('../helper', __FILE__)

class VictoropsTest < PapertrailServices::TestCase

  def test_config
    svc = service(:logs, {:token => 'a sample key'}, payload)
    assert_raises(PapertrailServices::Service::ConfigurationError) { svc.receive_logs }

    svc = service(:logs, {:routing_key => 'a different key'}, payload)
    assert_raises(PapertrailServices::Service::ConfigurationError) { svc.receive_logs }
  end

  def test_source_names
    svc = service(:logs, {:token => 'a sample token',
                          :routing_key => 'a different token'},
                  payload)

    # This is using the current test data from log_helpers.rb will fail if
    # that data is changed
    assert_equal(svc.source_names(svc.payload[:events], 1), "from 2 hosts")
    assert_equal(svc.source_names(svc.payload[:events], 5), "alien, lullaby")
    
  end
  
  def test_logs
    svc = service(:logs, {:token => 'a sample token',
                          :routing_key => 'a different token'},
                  payload)

    http_stubs.post '/1/messages.json' do |env|
      [200, {:content_type => "application/json"}, { :status => 1 }.to_json]

      svc.receive_logs
    end

  end

  def service(*args)
    super Service::Victorops, *args
  end
  
end
