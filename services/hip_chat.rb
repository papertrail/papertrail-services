# encoding: utf-8
require 'hipchat-api'

class Service::HipChat < Service
  attr_writer :hipchat

  def receive_logs
    raise_config_error 'Missing hipchat token' if settings[:token].to_s.empty?
    raise_config_error 'Missing hipchat room_id' if settings[:room_id].to_s.empty?

    events = payload[:events]
    search_name = payload[:saved_search][:name]
    search_url = payload[:saved_search][:html_search_url]
    matches = pluralize(events.size, 'match')

    message = %{"#{search_name}" search found #{matches} — #{search_url}}
    paste = events.map { |event| "<pre>#{syslog_format(event)}</pre>" }.join('<br />')

    deliver message
    deliver paste if paste && paste != ''
  rescue
    raise_config_error "Error sending hipchat message: #{$!}"
  end

  def deliver(message)
    hipchat.rooms_message(settings[:room_id], 'Papertrail', message)
  end

  def hipchat
    @hipchat ||= ::HipChat::API.new(settings[:token])
  end
end
