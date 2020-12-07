class Service::OpsGenie < Service

  def receive_logs
    raise_config_error 'Missing OpsGenie api key' if settings[:api_key].to_s.empty?
    
    params = {
      :apiKey => settings[:api_key],
      :payload => payload
    }
    url = "https://api.opsgenie.com/v1/json/papertrail"
    
    resp = http_post url, params, 'Content-Type' => 'application/json'
      unless resp.success?
        error_body = Yajl::Parser.parse(resp.body) rescue nil
        if error_body
          raise_config_error("Unable to send: #{error_body['errors'].join(", ")}")
        else
          puts "opsgenie: #{payload[:saved_search][:id]}: #{resp.status}: #{resp.body}"
        end
      end
    end
  end
end
