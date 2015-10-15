# coding: utf-8

require 'rushover'
require 'time'

class Service::Pushover < Service
  attr_writer :pushover

  def receive_logs
    raise_config_error 'Missing pushover app token' if
      settings[:token].to_s.empty?
    raise_config_error 'Missing pushover user token' if
      settings[:user_key].to_s.empty?

    events = payload[:events]
    
    hosts = events.collect { |e| e[:source_name] }.sort.uniq
    title = payload[:saved_search][:name]
    if hosts.length < 5
        title = "#{title} (#{hosts.join(', ')})"
      else
        title = "#{title} (from #{hosts.length} hosts)"
    end

    message = events.collect { |item|
      syslog_format(item)
    }

    message = message[0..1020] + "..." if message.length > 1024

    if message.empty?
      raise_config_error "Could not process payload"
    end

    resp = pushover.notify(settings[:user_key],
                           message,
                           {title: title,
                            timestamp: Time.iso8601(events[0][:received_at]).to_i,
                            url: payload[:saved_search][:html_search_url],
                            url_title: "View logs on Papertrail"})

    unless resp.ok?
      puts "pushover: #{resp.to_s}"

      raise_config_error "Failed to post to Pushover"
    end
  end

  
  def pushover
    @pushover ||= Rushover::Client.new(settings[:token])
  end
  
end
