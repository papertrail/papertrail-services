# encoding: utf-8
class Service::Campfire < Service
  attr_writer :campfire

  def receive_logs
    raise_config_error 'Missing campfire token' if settings[:token].to_s.empty?

    unless room = find_room
      raise_config_error 'No such campfire room'
    end

    message = %{"#{payload[:saved_search][:name]}" search found #{Pluralize.new('match', :count => payload[:events].length)} in the past #{payload[:frequency]} — #{payload[:saved_search][:html_search_url]}}
    paste = payload[:events].collect { |event| syslog_format(event) }.join("\n")

    play_sound = settings[:play_sound].to_i == 1
    sound = settings['sound'].blank? ? 'rimshot' : settings['sound']

    room.speak message
    if paste && paste != ''
      room.paste paste
    end
    if play_sound && room.respond_to?(:play)
      room.play sound
    end
  rescue Faraday::Error::ConnectionFailed
    raise_config_error "Connection refused — invalid campfire subdomain."
  end

  def campfire_hostname
    settings[:subdomain].to_s[/^(.+)(\.campfirenow\.com)?$/, 1]
  end

  def campfire
    @campfire ||= Tinder::Campfire.new(campfire_hostname, :token => settings[:token])
  rescue Tinder::AuthenticationFailed => e
    raise_config_error 'Authentication failed — invalid token'
  end

  def find_room
    room = campfire.find_room_by_name(settings[:room])
  rescue StandardError
  end
end
