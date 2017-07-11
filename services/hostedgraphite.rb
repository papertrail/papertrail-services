# encoding: utf-8
class Service::HostedGraphite < Service
  def receive_logs
    raise_config_error 'Missing API Key' if settings[:api_key].to_s.empty?
    raise_config_error 'Missing metric name' if settings[:metric].to_s.empty?

    metric_url = 'https://www.hostedgraphite.com/api/v1/sink'
    base_metric = settings[:metric]
    search = payload[:saved_search]
    data_to_send = Array.new
    if payload.key?(:counts)
      payload[:counts].each do |metric|
        src = metric[:source_name].gsub(/\s+/, "")
        full_metric = base_metric + '.' + src
        metric[:timeseries].each do |timestamp, val|
          mstring = [full_metric, val, timestamp, "\n"].join(" ")
          data_to_send.push(mstring)
        end
      end
    end

    http.basic_auth settings[:api_key], ""
    http.headers['content-type'] = 'application/json'
    data_to_send.each do |metric|
      resp = http_post metric_url do |req|
        req.body = metric
      end

      unless resp.success?
        puts "hostedgraphite: #{payload[:saved_search][:id]}: #{resp.status}: #{resp.body}"
        raise_config_error("Hosted Graphite metrics could not be sent")
      end
    end
  end
end
