# encoding: utf-8
class Service::GeckoBoard < Service
  attr_writer :geckoboard

  def receive_logs
    raise_config_error 'Missing GeckoBoard API key' if settings[:token].to_s.empty?
    raise_config_error 'Missing GeckoBoard widget key' if settings[:widget_key].to_s.empty?

    deliver(settings[:token], settings[:widget_key], payload[:events].size)
  rescue
    raise_config_error "Error sending GeckoBoard message: #{$!}"
  end

  def deliver(token, widget_key, value)
    # http://docs.geckoboard.com/api/push.html
    res = http_post URI.join("https://push.geckoboard.com/v1/send/", token).to_s do |req|
      req.headers[:content_type] = 'application/json'

      req.body = {
        :api_key => widget_key,
        :data => {
          :item => [
            { 
              :text => "",
              :value => value
            }
          ]
        }
      }.to_json
    end

    if !res.success?
      msg = "Error connecting to GeckoBoard (#{res.status})"
      if res.body
        msg += ": " + res.body[0..255]
      end
      raise_config_error(msg)
    end
  end
end