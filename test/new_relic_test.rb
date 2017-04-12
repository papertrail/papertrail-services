require File.expand_path('../helper', __FILE__)

class NewRelicTest < PapertrailServices::TestCase
  def test_config
    svc = service(:logs, {}.with_indifferent_access, payload)
    assert_raises(PapertrailServices::Service::ConfigurationError) { svc.receive_logs }

    svc = service(:logs, { 'insights_api_key' => "foobar" }.with_indifferent_access, payload)
    assert_raises(PapertrailServices::Service::ConfigurationError) { svc.receive_logs }

    svc = service(:logs, { 'account_id' => "1929219" }.with_indifferent_access, payload)
    assert_raises(PapertrailServices::Service::ConfigurationError) { svc.receive_logs }
  end
  
  def test_logs
    svc = service(:logs, { 'insights_api_key' => '9872--3042dtshN3oen', "account_id" => "531007"}.with_indifferent_access, payload)

    http_stubs.post "/v1/accounts/531007/events" do |env|
      [200, {}, ""]
    end

    svc.receive_logs
  end
  
  # TODO: Other things to test
  # A formatted event contains an eventType and search_name key 
  # A formatted event's received_at is in UNIX epoch
  # A message longer than 4K is truncated
  # If the payload has > 1000 events, handle that case
  
  def service(*args)
    super Service::NewRelic, *args
  end
  
end