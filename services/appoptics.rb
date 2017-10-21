# encoding: utf-8

class Service::AppOptics < Service  
  def receive_logs
    default_metrics = Hash.new do |metrics, name|
      metrics[name] = default_timeseries
    end

    metrics = payload[:events].
      each_with_object(default_metrics) do |event, metrics|
        received_at = Time.iso8601(event[:received_at]).to_i
        rounded     = round_to_minute(received_at)
        metrics[event[:source_name]][rounded] += 1
      end

    submit_metrics metrics
  end

  def receive_counts
    metrics = payload[:counts].each_with_object({}) do |count, metrics|
      metrics[count[:source_name]] = count[:timeseries].
        each_with_object(default_timeseries) do |(time, count), timeseries|
          time = time.to_i
          timeseries[round_to_minute(time)] += count
        end
    end

    submit_metrics metrics
  end

  def default_timeseries
    Hash.new do |timeseries, time|
      timeseries[time] = 0
    end
  end

  def round_to_minute(time)
    time - (time % 60)
  end

  def metric_name
    settings[:name].gsub(/ +/, '_')
  end

  def appoptics_token
    settings[:token].to_s.strip
  end

  def submit_metrics(metrics)
    queue = enqueue_metrics(metrics, metric_name, appoptics_token)
    return if queue.empty?
    queue.submit
  rescue AppOptics::Metrics::ClientError => e
    if e.message !~ /is too far in the past/
      raise Service::ConfigurationError,
        "Error sending to AppOptics: #{e.message}"
    end
  rescue AppOptics::Metrics::CredentialsMissing, AppOptics::Metrics::Unauthorized
    raise Service::ConfigurationError,
      "Error sending to AppOptics: Missing or invalid token"
  rescue AppOptics::Metrics::MetricsError => e
    raise Service::ConfigurationError,
      "Error sending to AppOptics: #{e.message}"
  end

  def enqueue_metrics(metrics, name, token)
    queue = create_queue(token)
    metrics.each do |source_name, hash|
      hash.each do |time, count|
        queue.add name => {
          :source       => source_name,
          :value        => count,
          :measure_time => time,
          :type         => 'gauge',
          :attributes   => {
            :backlink => payload[:saved_search][:html_search_url]
          }
        }
      end
    end

    queue
  end

  def create_queue(token)
    client = AppOptics::Metrics::Client.new
    client.authenticate(token)
    client.agent_identifier("Papertrail-Services/1.0")
    client.new_queue
  end
end
