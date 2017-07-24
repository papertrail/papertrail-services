# encoding: utf-8
class Service::Mattermost < Service
  def receive_logs
    mattermost_url, display_messages = extract_from(settings)
    raise_config_error 'Missing Mattermost URL' if mattermost_url.empty?

    data = {
      :text => build_message(payload),
      :parse => 'none',
      :attachments => build_attachments(payload[:events], display_messages)
    }

    response = post(mattermost_url, data)
    raise_if_needed(response, payload)
  end

  private

  def extract_from(settings)
    [
      settings[:mattermost_url].to_s,
      (settings[:dont_display_messages].to_i != 1)
    ]
  end

  def build_message(payload)
    "#{payload[:saved_search][:name]} search found " \
    "#{Pluralize.new('match', :count => payload[:events].length)} " \
    "#{frequency_phrase(payload[:frequency])} " \
    "— <#{payload[:saved_search][:html_search_url]}|" \
    "#{payload[:saved_search][:html_search_url]}>"
  end

  def build_attachments(events, display_messages)
    return nil unless events.present? && display_messages

    body = build_body(events)

    [{
      :text => format_text_attachment(body),
      :mrkdwn_in => ["text"],
      :fallback => body,
    }]
  end

  def format_text_attachment(body)
    # Provide some basic escaping of ``` in messages
    body = body.gsub('```', '` ` `')

    "```" + body + "```"
  end

  # Mattermost truncates attachments at 3872 bytes
  # It's written nowhere, but we found it by dicotomy
  # Kudos us !!!
  def build_body(events, limit = 3872)
    body = ''

    events.each do |event|
      message = syslog_format(event) + "\n"
      if (body.length + message.length) < limit
        body << message
      else
        break
      end
    end

    body
  end

  def post(mattermost_url, data)
    http.headers['content-type'] = 'application/json'
    http_post mattermost_url, convert_to_json(data)
  end

  def convert_to_json(data)
    data.reject{ |key, value| value.nil? }.to_json
  end

  def raise_if_needed(response, payload)
    return if response.success?
    puts "mattermost: #{payload[:saved_search][:id]}: #{response.status}: #{response.body}"
    raise_config_error "Could not submit logs"
  end
end
