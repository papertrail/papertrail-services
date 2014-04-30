require File.expand_path('../helper', __FILE__)

class SlackTest < PapertrailServices::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_logs
    svc = service(:logs, { :slack_url => "https://site.slack.com/services/hooks/incoming-webhook?token=aaaa" }, payload)

    @stubs.post '/services/hooks/incoming-webhook' do |env|
      [200, {}, '']
    end

    svc.receive_logs
  end

  def test_long_logs
    long_payload = payload.dup
    long_payload[:events] *= 100

    svc = service(:logs, { :slack_url => "https://site.slack.com/services/hooks/incoming-webhook?token=aaaa" }, long_payload)

    @stubs.post '/services/hooks/incoming-webhook' do |env|
      [200, {}, '']
    end

    svc.receive_logs
  end

  def test_format_content_with_truncation
    long_payload = payload.dup
    long_payload[:events] *= 100

    slack = Service::Slack.new
    message = slack.format_content(long_payload[:events])

    assert message.length < 8000
  end

  def service(*args)
    super Service::Slack, *args
  end
end