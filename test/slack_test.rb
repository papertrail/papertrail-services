require File.expand_path('../helper.rb', __FILE__)

class SlackTest < PapertrailServices::TestCase
  def test_logs
    svc = service(:logs, { :slack_url => "https://site.slack.com/services/hooks/incoming-webhook?token=aaaa" }, payload)

    http_stubs.post '/services/hooks/incoming-webhook' do |env|
      [200, {}, '']
    end

    svc.receive_logs
  end

  def test_long_logs
    long_payload = payload.dup
    long_payload[:events] *= 100

    svc = service(:logs, { :slack_url => "https://site.slack.com/services/hooks/incoming-webhook?token=aaaa" }, long_payload)

    http_stubs.post '/services/hooks/incoming-webhook' do |env|
      [200, {}, '']
    end

    svc.receive_logs
  end

  def test_build_attachments
    long_payload = payload.dup
    long_payload[:events] *= 100

    slack = Service::Slack.new
    attachment = slack.build_attachments(long_payload[:events])
    assert attachment[0][:text].length < 8000
    assert attachment[0][:fallback].length < 8000
  end

  def test_no_messages
    empty_payload = payload.dup
    empty_payload[:events] = []

    svc = service(:logs, { :slack_url => "https://site.slack.com/services/hooks/incoming-webhook?token=aaaa" }, empty_payload)

    post = false
    http_stubs.post '/services/hooks/incoming-webhook' do |env|
      post = true
      body = JSON(env[:body])

      assert !body.has_key?('attachments'), 'Expected no attachments without events'

      [200, {}, '']
    end

    svc.receive_logs

    assert post, 'Expected post to service webhook'
  end

  def test_dont_display_messages
    svc = service(:logs, { :dont_display_messages => 1, :slack_url => "https://site.slack.com/services/hooks/incoming-webhook?token=aaaa" }, payload)

    post = false
    http_stubs.post '/services/hooks/incoming-webhook' do |env|
      post = true
      body = JSON(env[:body])

      assert !body.has_key?('attachments'), 'Expected no attachments without events'

      [200, {}, '']
    end

    svc.receive_logs

    assert post, 'Expected post to service webhook'
  end

  def service(*args)
    super Service::Slack, *args
  end
end
