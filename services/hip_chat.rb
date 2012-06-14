# encoding: utf-8
require 'hipchat-api'

class Service::HipChat < Service
  attr_writer :hipchat

  MESSAGE_LIMIT = 10000 - "<pre>\n</pre>".size

  def receive_logs
    raise_config_error 'Missing hipchat token' if settings[:token].to_s.empty?
    raise_config_error 'Missing hipchat room_id' if settings[:room_id].to_s.empty?

    events = payload[:events]
    search_name = payload[:saved_search][:name]
    search_url = payload[:saved_search][:html_search_url]
    matches = pluralize(events.size, 'match')

    deliver %{<a href="#{search_url}">#{search_name}</a> search found #{matches}}

    buf = ''

    events.each do |event|
      new_entry = format_entry(event) + "\n"

      if buf.size + new_entry.size > MESSAGE_LIMIT
        deliver_preformatted(buf)
        buf = ''
        redo
      end

      buf << new_entry
    end

    deliver_preformatted(buf) unless buf.empty?
  rescue
    raise_config_error "Error sending hipchat message: #{$!}"
  end

  def format_entry(entry)
    received_at = Time.zone.parse(entry[:received_at]).strftime('%b %d %X')

    "<b>#{received_at} #{h(entry[:source_name])} #{h(entry[:program])}:</b> #{h(entry[:message])}"
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
