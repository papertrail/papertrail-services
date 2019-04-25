require File.expand_path('../helper.rb', __FILE__)

class MattermostTest < PapertrailServices::TestCase
  def test_logs
    svc = service(:logs, { :mattermost_url => "http://www.fake-mattermost.com/hooks/FakeHook" }, payload)

    http_stubs.post '/hooks/FakeHook' do |env|
      [200, {}, '']
    end

    svc.receive_logs
  end

  def test_long_logs
    long_payload = payload.dup
    long_payload[:events] *= 100

    svc = service(:logs, { :mattermost_url => "http://www.fake-mattermost.com/hooks/FakeHook" }, long_payload)

    http_stubs.post '/hooks/FakeHook' do |env|
      [200, {}, '']
    end

    svc.receive_logs
  end

  def test_build_attachments
    long_payload = payload.dup
    long_payload[:events] *= 100

    svc = service(:logs, { :mattermost_url => "http://www.fake-mattermost.com/hooks/FakeHook" }, long_payload)

    http_stubs.post '/hooks/FakeHook' do |env|
      body = JSON(env[:body])

      assert body['attachments'][0]["text"].length < 8000
      assert body['attachments'][0]["fallback"].length < 8000

      [200, {}, '']
    end

    svc.receive_logs
  end

  def test_no_messages
    empty_payload = payload.dup
    empty_payload[:events] = []

    svc = service(:logs, { :mattermost_url => "http://www.fake-mattermost.com/hooks/FakeHook" }, empty_payload)

    post = false
    http_stubs.post '/hooks/FakeHook' do |env|
      post = true
      body = JSON(env[:body])

      assert !body.has_key?('attachments'), 'Expected no attachments without events'

      [200, {}, '']
    end

    svc.receive_logs

    assert post, 'Expected post to service webhook'
  end

  def test_dont_display_messages
    svc = service(:logs, { :dont_display_messages => 1, :mattermost_url => "http://www.fake-mattermost.com/hooks/FakeHook" }, payload)

    post = false
    http_stubs.post '/hooks/FakeHook' do |env|
      post = true
      body = JSON(env[:body])

      assert !body.has_key?('attachments'), 'Expected no attachments without events'

      [200, {}, '']
    end

    svc.receive_logs

    assert post, 'Expected post to service webhook'
  end

  def service(*args)
    super Service::Mattermost, *args
  end
end
