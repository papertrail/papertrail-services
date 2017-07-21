# encoding: utf-8

class Service::Neptune < Service
  def receive_logs
    raise_config_error 'Missing Neptune API key' if
      settings[:api_key].to_s.empty?

    size_limit = 5.megabytes # Neptune specified 5mb as of Feb 2016

    url = "https://www.neptune.io/api/v1/trigger/channel/papertrail/#{settings[:api_key]}"
    resp = http_post url do |req|
      req.headers = {
        'Content-Type' => 'application/json'
      }
      req.body = json_limited(payload, size_limit)
    end

    unless resp.success?
      puts "Neptune: #{resp.body.to_s}"
      raise_config_error "Failed to post to Neptune."
    end
  end
end
