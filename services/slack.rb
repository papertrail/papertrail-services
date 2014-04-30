# encoding: utf-8
class Service::Slack < Service
  def receive_logs
    raise_config_error 'Missing slack webhook' if settings[:slack_url].to_s.empty?
    raise_config_error "Slack webhook must point to slack.com" unless settings[:slack_url].to_s.match(/slack\.com/)
    
    message = %{"#{payload[:saved_search][:name]}" search found #{pluralize(payload[:events].length, 'match')} — <#{payload[:saved_search][:html_search_url]}|#{payload[:saved_search][:html_search_url]}>}
    attachment = format_content(payload[:events])

    data = {
      :text => message,
      :parse => 'none',
      :attachments => [
        {
          :text => attachment,
          :mrkdwn_in => ["text"]
        }
      ]
    }
    
    http.headers['content-type'] = 'application/json'
    response = http_post settings[:slack_url], data.to_json

    unless response.success?
      puts "slack: #{payload[:saved_search][:id]}: #{response.status}: #{response.body}"
      raise_config_error "Could not submit logs"
    end
  end

  # Slack truncates attachments at 8000 bytes
  def format_content(events, limit = 7990)
    body = ''

    events.each do |event|
      message = syslog_format(event) + "\n"
      if (body.length + message.length) < limit
        body << message
      else
        break
      end
    end

    # Provide some basic escaping of ``` in messages
    body = body.gsub('```', '` ` `')

    "```" + body + "```"
  end
end