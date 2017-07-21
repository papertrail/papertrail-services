# coding: utf-8

class Service::Zapier < Service
  attr_writer :zapier

  def receive_logs
    size_limit = 5.megabytes # Zapier specified 5mb as of September 2015

    raise_config_error 'Missing Zapier URL' if
      settings[:url].to_s.empty?

    http.headers['content-type'] = 'application/json'
    resp = http_post settings[:url], json_limited(payload, size_limit)

    unless resp.status == 200
      puts "zapier: #{resp.to_s}"
      raise_config_error "Failed to post to Zapier"
    end
  end

end
