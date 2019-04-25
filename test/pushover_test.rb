require File.expand_path('../helper.rb', __FILE__)

class PushoverTest < PapertrailServices::TestCase
  def test_config
    svc = service(:logs, {:token => 'a sample token'}, payload)
    assert_raises(PapertrailServices::Service::ConfigurationError) { svc.receive_logs }

    svc = service(:logs, {:user_key => 'a different token'}, payload)
    assert_raises(PapertrailServices::Service::ConfigurationError) { svc.receive_logs }
  end

  def test_logs
    svc = service(:logs, {:token => 'a sample token', :user_key => 'a different token'}, payload)

    body = nil
    http_stubs.post '/1/messages.json' do |env|
      body = CGI.parse(env[:body])
      [200, {}, '']
    end

    svc.receive_logs

    assert body.present?
    assert_match /Jul 22 14:10:01 alien CROND/, body['message'][0]
    assert_equal 'cron (alien, lullaby)', body['title'][0]
    assert_equal 'https://papertrailapp.com/searches/392', body['url'][0]
  end

  def test_no_logs
    svc = service(:logs, {:token => 'a sample token', :user_key => 'a different token'}, payload.dup.merge(:events => []))

    body = nil
    http_stubs.post '/1/messages.json' do |env|
      body = CGI.parse(env[:body])
      [200, {}, '']
    end

    svc.receive_logs

    assert body.present?
    assert_equal '0 matches found in the past minute', body['message'][0]
    assert_equal 'cron', body['title'][0]
    assert_equal 'https://papertrailapp.com/searches/392', body['url'][0]
  end

  def service(*args)
    super Service::Pushover, *args
  end
end
