# encoding: utf-8
class Service::LibratoMetrics < Service
  def receive_logs
    name = settings[:name].gsub(/ +/, '_')

    # values[hostname][time]
    values = Hash.new do |h,k|
      h[k] = Hash.new do |i,l|
        i[l] = 0
      end
    end

    payload[:events].each do |event|
      time = Time.parse(event[:received_at]).to_i
      values[event[:source_name]][time] += 1
    end

    client = Librato::Metrics::Client.new
    client.authenticate(settings[:user], settings[:token])
    client.agent_identifier("Papertrail-Services/1.0")

    queue = client.new_queue

    values.each do |source_name, hash|
      hash.each do |time, count|
        queue.add name => {
          :source       => source_name,
          :value        => count,
          :measure_time => time,
          :type         => 'gauge'
        }
      end
    end

    unless queue.empty?
      queue.submit
    end
  rescue Librato::Metrics::CredentialsMissing, Librato::Metrics::Unauthorized
    raise_config_error("Error sending to Librato Metrics: Invalid email address or token")
  rescue Librato::Metrics::MetricsError => e
    raise_config_error("Error sending to Librato Metrics: #{e.message}")
  end
end
