# encoding: utf-8
require 'hipchat-api'

class Service::HipChat < Service
  attr_writer :hipchat

  def receive_logs
    raise_config_error 'Missing hipchat token' if settings[:token].to_s.empty?
    raise_config_error 'Missing hipchat room_id' if settings[:room_id].to_s.empty?

    message = %{"#{payload[:saved_search][:name]}" search found #{pluralize(payload[:events].length, 'match')} — #{payload[:saved_search][:html_search_url]}}
    paste = payload[:events].collect { |event| "<pre>#{syslog_format(event)}</pre>" }.join("<br />")

    deliver message
    if paste && paste != ''
      deliver paste
    end
  rescue
    raise_config_error "Connection refused — hipchat message rejected."
  end

  def deliver(message)
    hipchat.rooms_message(settings[:room_id], 'Papertrail', message)
  end

  def hipchat
    @hipchat ||= ::HipChat::API.new(settings[:token])
  end
end