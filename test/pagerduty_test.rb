require File.expand_path('../helper.rb', __FILE__)

class PagerdutyTest < PapertrailServices::TestCase
  def test_size_limit
    assert(payload.to_json.length > 1400, 'Test requires larger sample payload')
    svc = service(:logs, { :service_key => 'k' }, payload)

    # Run payload through pagerduty.rb, since it alters the JSON format.
    body = nil
    http_stubs.post '/generic/2010-04-15/create_event.json' do |env|
      body = JSON(env[:body], symbolize_names: true)
      [200, {}, '']
    end
    svc.receive_logs

    assert_not_nil body
    assert(body.to_json.length > 600)
    limited_body = svc.json_limited(body, 600, body[:details][:messages])
    assert(limited_body.length <= 600)
  end

  def test_logs
    svc = service(:logs, { :service_key => 'k' }, payload)

    body = nil
    http_stubs.post '/generic/2010-04-15/create_event.json' do |env|
      body = JSON(env[:body], symbolize_names: true)
      [200, {}, '']
    end

    svc.receive_logs

    assert_not_nil body
    assert_equal 5, body[:details][:messages].length
    assert_equal 'https://papertrailapp.com/searches/392?centered_on_id=31171139124469760', body[:details][:log_start_url]
    assert_equal 'https://papertrailapp.com/searches/392?centered_on_id=31181206313902080', body[:details][:log_end_url]
  end

  def test_no_logs
    svc = service(:logs, { :description => 'PagerDuty test', :service_key => 'k' }, payload.dup.merge(:events => []))

    body = nil
    http_stubs.post '/generic/2010-04-15/create_event.json' do |env|
      body = JSON(env[:body], symbolize_names: true)
      [200, {}, '']
    end

    svc.receive_logs

    assert_not_nil body
    assert_equal 'PagerDuty test found 0 matches in the past minute', body[:description]
    assert_equal 'https://papertrailapp.com/searches/392', body[:details][:search_url]
  end

  def test_logs_with_incident_key
    svc = service(:logs, { :service_key => 'k', :incident_key => '%HOST%/PAPERTRAIL' }, payload)

    body = nil
    http_stubs.post '/generic/2010-04-15/create_event.json' do |env|
      body = JSON(env[:body], symbolize_names: true)
      [200, {}, '']
    end

    svc.receive_logs

    assert_not_nil body
    assert_equal 'lullaby/PAPERTRAIL', body[:incident_key]
  end


  def service(*args)
    super Service::Pagerduty, *args
  end
end
