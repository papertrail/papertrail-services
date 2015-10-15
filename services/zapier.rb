# coding: utf-8

class Service::Zapier < Service
  attr_writer :zapier

  def json_limited(payload, size_limit)
    ret = payload.to_json

    while ret.length > size_limit
      # This should only run once in the vast majority of cases, but the loop
      # is necessary for pathological inputs
      estimate = 0.9 * size_limit / ret.length
      new_length = (payload[:events].length * estimate).floor
      payload[:events] = payload[:events][0 .. new_length - 1]
      ret = payload.to_json
    end

    ret
  end

  def receive_logs
    size_limit= 5242880 # Zapier specified 5mb as of September 2015
    
    raise_config_error 'Missing Zapier URL' if
      settings[:zapier_url].to_s.empty?

    http.headers['content-type'] = 'application/json'
    resp = http_post settings[:zapier_url], json_limited(payload, size_limit)
    
    unless resp.status == 200
      puts "zapier: #{resp.to_s}"
      raise_config_error "Failed to post to Zapier"
    end
  end

end
