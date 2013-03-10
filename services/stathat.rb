# encoding: utf-8
class Service::Stathat < Service
  def receive_logs
    count = payload["events"].size

    raise_config_error 'Missing EZ Key' if settings[:ezkey].to_s.empty?
    raise_config_error 'Missing stat name' if settings[:stat].to_s.empty?

    http_get "http://api.stathat.com/ez", :ezkey => settings[:ezkey],
      :stat => settings[:stat],
      :count => count
  rescue Faraday::Error::ConnectionFailed
    raise_config_error "Connection refused."
  end
end
