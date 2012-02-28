# encoding: utf-8
require 'cgi'
require 'hipchat-api'

class Service::HipChat < Service
  attr_writer :hipchat

  MESSAGE_LIMIT = 5000 - ("<pre>\n"+'</pre>').size

  def receive_logs
    raise_config_error 'Missing hipchat token' if settings[:token].to_s.empty?
    raise_config_error 'Missing hipchat room_id' if settings[:room_id].to_s.empty?

    events = payload[:events]
    search_name = payload[:saved_search][:name]
    search_url = payload[:saved_search][:html_search_url]
    matches = pluralize(events.size, 'match')

    deliver %{"#{search_name}" search found #{matches} — #{search_url}}

    unless events.size.zero?
      logs, remaining = [], MESSAGE_LIMIT
      events.each do |event|
        new_entry = CGI.escapeHTML(syslog_format(event)) + "\n"
        remaining -= new_entry.size
        if remaining > 0
          logs << new_entry
        else
          deliver_preformatted(logs.join)
          logs, remaining = [new_entry], MESSAGE_LIMIT
        end
      end

      deliver_preformatted(logs.join)
    end
  rescue
    raise_config_error "Error sending hipchat message: #{$!}"
  end

  def deliver_preformatted(message)
    deliver "<pre>\n" + message + '</pre>'
  end

  def deliver(message)
    hipchat.rooms_message(settings[:room_id], 'Papertrail', message)
  end

  def hipchat
    @hipchat ||= ::HipChat::API.new(settings[:token])
  end
end
