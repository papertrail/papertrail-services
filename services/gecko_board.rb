# encoding: utf-8
class Service::GeckoBoard < Service
  attr_writer :geckoboard

  def receive_logs
    raise_config_error 'Missing Geckoboard API key' if settings[:token].to_s.empty?
    raise_config_error 'Missing Geckoboard widget key' if settings[:widget_key].to_s.empty?

    deliver(settings[:token], settings[:widget_key], payload[:events].size)
  rescue
    raise_config_error "Error sending Geckoboard message: #{$!}"
  end

  def deliver(token, widget_key, value)
    # https://developer.geckoboard.com/#pushing-to-your-widget 
    res = http_post URI.join("https://push.geckoboard.com/v1/send/", widget_key).to_s do |req|
      req.headers[:content_type] = 'application/json'

      req.body = {
        :api_key => token,
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
      msg = "Error connecting to Geckoboard (#{res.status})"
      if res.body
        msg += ": " + res.body[0..255]
      end
      raise_config_error(msg)
    end
  end
end
