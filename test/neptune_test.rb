require File.expand_path('../helper', __FILE__)

class NeptuneTest < PapertrailServices::TestCase

  def test_config
    svc = service(:logs, {:api_key => ''}, payload)
    assert_raises(PapertrailServices::Service::ConfigurationError) { svc.receive_logs }
  end

  def test_size_limit
    assert(payload.to_json.length > 1400, 'Test requires larger sample payload')
    svc = service(:logs, {:api_key => 'test_api_key'}, payload)
    limited_payload = svc.json_limited(payload, 1400)
    assert(limited_payload.length <= 1400)
  end

  def test_logs
    svc = service(:logs, {:api_key => 'test_api_key'}, payload)
    http_stubs.post '/api/v1/trigger/channel/papertrail/test_api_key' do |env|
      payload = JSON.parse(env[:body])
      assert_equal 392, payload['saved_search']['id']
      assert_equal "cron", payload['saved_search']['name']
      assert_equal "31181206313902080", payload['max_id']
      [200, {:content_type => "application/json"}, { :status => 1 }.to_json]
    end

    svc.receive_logs
  end

  def service(*args)
    super Service::Neptune, *args
  end

end
