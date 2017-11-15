require File.expand_path('../helper', __FILE__)

class MailTest < PapertrailServices::TestCase
  def setup

  end

  def test_logs
    svc = service(:logs, { :addresses => 'eric@papertrail.com' }, payload)

    svc.mail_message.perform_deliveries = false

    svc.receive_logs
  end

  def test_mail_message
    svc = service(:logs, { :addresses => 'eric@papertrail.com' }, payload)

    message = svc.mail_message

    assert_not_nil message
  end

  def test_html_syslog_format
    svc = service(:logs, { :addresses => 'eric@papertrail.com' }, payload)

    url = "https://papertrailapp.com/groups/999/events?q=searchstring&q_id=99999999"
    syslog_format = svc.html_syslog_format(payload[:events].first, url)

    assert_match '<a href="https://papertrailapp.com/groups/999/events?', syslog_format
    assert_match 'centered_on_id=31171139124469760', syslog_format
    assert_match 'q=searchstring', syslog_format
    assert_match 'q_id=99999999', syslog_format
  end

  def test_mail_message_multiple_recipients
    svc = service(:logs, { :addresses => 'eric@papertrail.com,troy@papertrail.com;larry@papertrail.com ryan@papertrail.com' }, payload)

    message = svc.mail_message

    expected = %w(eric@papertrail.com troy@papertrail.com larry@papertrail.com ryan@papertrail.com)
    assert_equal expected, message.to
  end

  def test_mail_message_fancy_recipients
    svc = service(:logs, { :addresses => 'Eric <eric@papertrail.com>,troy@papertrail.com;larry@papertrail.com' }, payload)

    message = svc.mail_message

    expected = %w(eric@papertrail.com troy@papertrail.com larry@papertrail.com)
    assert_equal expected, message.to
  end

  def test_html
    svc = service(:logs, { }, payload)

    html = svc.html_email

    assert_not_nil html
  end

  def test_text
    svc = service(:logs, { }, payload)

    text = svc.text_email

    assert_not_nil text
  end

  def service(*args)
    super Service::Mail, *args
  end
end
