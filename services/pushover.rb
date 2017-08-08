# coding: utf-8

class Service::Pushover < Service
  def post_data(body)
    message = body[:message]
    message = message[0..1020] + "..." if message.length > 1024

    if message.empty?
      raise_config_error "Could not process payload"
    end

    post_data = {
      :token => settings[:token],
      :user => settings[:user_key],
      :title => body[:title],
      :message => message,
      :timestamp => body[:timestamp].to_i,
      :url => payload[:saved_search][:html_search_url],
      :url_title => "View logs on Papertrail"
    }

    resp = http_post("https://api.pushover.net/1/messages.json", post_data.to_json)

    unless resp.success?
      puts "pushover: #{resp.to_s}"

      raise_config_error "Failed to post to Pushover"
    end
  end

  def receive_logs
    raise_config_error 'Missing pushover app token' if
      settings[:token].to_s.empty?
    raise_config_error 'Missing pushover user token' if
      settings[:user_key].to_s.empty?

    events = payload[:events]
    title  = payload[:saved_search][:name]

    if events.present?
      hosts = events.collect { |e| e[:source_name] }.sort.uniq

      if hosts.length < 5
        title = "#{title} (#{hosts.join(', ')})"
      else
        title = "#{title} (from #{hosts.length} hosts)"
      end

      message = events.collect { |item|
        syslog_format(item)
      }

      body = {
        :title => title,
        :message => message,
        :timestamp => Time.iso8601(events[0][:received_at])
      }

      post_data(body)
    else
      frequency = frequency_phrase(payload[:frequency])
      message   = %{0 matches found #{frequency}}

      body = {
        :title => title,
        :message => message,
        :timestamp => Time.now
      }

      post_data(body)
    end
  end
end
