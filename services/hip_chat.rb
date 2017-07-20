# encoding: utf-8
require 'cgi'
require 'hipchat-api'

class Service::HipChat < Service
  attr_writer :hipchat

  MESSAGE_LIMIT = 5000 - ("<pre>\n"+'</pre>').size
  COLORS = %w{yellow red green purple gray random}

  def receive_logs
    raise_config_error 'Missing hipchat token' if settings[:token].to_s.empty?
    raise_config_error 'Missing hipchat room_id' if settings[:room_id].to_s.empty?

    dont_display_messages = settings[:dont_display_messages].to_i == 1
    color                 = settings[:color].to_s.downcase

    events      = payload[:events]
    frequency   = payload[:frequency]
    search_name = payload[:saved_search][:name]
    search_url  = payload[:saved_search][:html_search_url]

    color = 'yellow' unless COLORS.include?(color)

    matches = Pluralize.new('match', :count => events.size)

    deliver %{"#{search_name}" search found #{matches} in the past #{frequency} — <a href="#{search_url}">#{search_url}</a>}, color

    if !events.empty? && !dont_display_messages
      logs, remaining = [], MESSAGE_LIMIT
      events.each do |event|
        new_entry = CGI.escapeHTML(syslog_format(event)) + "\n"
        remaining -= new_entry.size
        if remaining > 0
          logs << new_entry
        else
          deliver_preformatted(logs.join, color)
          logs, remaining = [new_entry], MESSAGE_LIMIT
        end
      end

      deliver_preformatted(logs.join, color)
    end
  rescue
    raise_config_error "Error sending hipchat message: #{$!}"
  end

  def deliver_preformatted(message, color)
    deliver "<pre>\n" + message + '</pre>', color
  end

  def deliver(message, color)
    res = hipchat.rooms_message(settings[:room_id], 'Papertrail', message, settings[:notify], color)
    unless res.code == 200
      message = res.parsed_response['error']['message'] rescue "Responded with HTTP #{res.code}"
      raise message
    end
  end

  def hipchat
    @hipchat ||= ::HipChat::API.new(settings[:token])
  end
end
