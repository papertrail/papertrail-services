# encoding: utf-8
class Service::LibratoMetrics < Service
  def receive_logs
    # values[hostname][time]
    values = Hash.new do |h,k|
      h[k] = Hash.new do |i,l|
        i[l] = 0
      end
    end

    payload[:events].each do |event|
      time = Time.parse(event[:received_at])
      time = time.to_i - (time.to_i % 60)
      values[event[:source_name]][time] += 1
    end

    gauges = values.collect do |source_name, hash|
      hash.collect do |time, count|
        {
          :name => settings[:name].gsub(/ +/, '_'),
          :source => source_name,
          :value => count,
          :measure_time => time
        }
      end
    end.flatten

    http.basic_auth settings[:user], settings[:token]

    res = http_post 'https://metrics-api.librato.com/v1/metrics.json' do |req|
      req.headers[:content_type] = 'application/json'

      req.body = {
        :gauges => gauges
      }.to_json
    end

    if !res.success?
      msg = "Error connecting to Librato (#{res.status})"
      if res.body
        msg += ": " + res.body[0..255]
      end
      raise_config_error(msg)
    end
  end
end
