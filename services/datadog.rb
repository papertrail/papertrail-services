# encoding: utf-8
class Service::Datadog < Service
  def receive_logs
    raise_config_error 'Missing API Key' if settings[:api_key].to_s.empty?
    raise_config_error 'Missing metric name' if settings[:metric].to_s.empty?

    unless settings[:tags].to_s.empty?
      tags = settings[:tags].to_s.split(/,\s*/)
    end

    # values[hostname][time]
    values = Hash.new do |h,k|
      h[k] = Hash.new do |i,l|
        i[l] = 0
      end
    end

    payload[:events].each do |event|
      time = Time.iso8601(event[:received_at]).to_i
      values[event[:source_name]][time] += 1
    end

    serieses = []

    values.each do |hostname, points|
      serieses << {
        :metric => settings[:metric],
        :points => points.to_a,
        :host => hostname,
        :tags => tags,
        :type => 'counter'
      }
    end

    resp = http_post "https://app.datadoghq.com/api/v1/series" do |req|
      req.params = {
        :api_key => settings[:api_key]
      }
      req.headers = {
        'Content-Type' => 'application/json'
      }
      req.body = {
        :series => serieses
      }.to_json
    end

    unless resp.success?
      puts "datadog: #{payload[:saved_search][:id]}: #{resp.status}: #{resp.body}"
      raise_config_error "Could not submit metrics"
    end
  end
end
