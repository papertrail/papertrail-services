# encoding: utf-8
class Service::Stathat < Service
  def receive_counts
    raise_config_error 'Missing EZ Key' if settings[:ezkey].to_s.empty?
    raise_config_error 'Missing stat name' if settings[:stat].to_s.empty?

    submit_metric_data(counts_payload_to_metrics)
  end

  def receive_logs
    raise_config_error 'Missing EZ Key' if settings[:ezkey].to_s.empty?
    raise_config_error 'Missing stat name' if settings[:stat].to_s.empty?

    submit_metric_data(logs_payload_to_metrics)
  end

  def logs_payload_to_metrics
    counts = Hash.new do |h,k|
      h[k] = 0
    end

    payload[:events].each do |event|
      time = Time.iso8601(event[:received_at]).to_i
      counts[time] += 1
    end

    counts.map do |time, count|
      {
        :stat => settings[:stat],
        :count => count,
        :t => time
      }
    end
  end

  def counts_payload_to_metrics
    metrics = Hash.new { |h, k| h[k] = 0 }

    payload[:counts].each do |count|
      count[:timeseries].each do |t, i|
        metrics[t.to_i] += i
      end
    end

    metrics.map do |time, count|
      {
        :stat => settings[:stat],
        :count => count,
        :t => time
      }
    end
  end

  def submit_metric_data(data)
    # Submissions are limited to 1,000 datapoints, so we'll ensure we stay
    # way under by submitting 500 at a time
    data.each_slice(500) do |data_slice|
      begin
        resp = http_post "http://api.stathat.com/ez" do |req|
          req.headers[:content_type] = 'application/json'
          req.body = {
            :ezkey => settings[:ezkey],
            :data => data_slice
          }.to_json
        end

        unless resp && resp.success?
          Scrolls.log(:status => resp.status, :body => resp.body)
          raise_config_error "Could not submit metrics"
        end
      rescue Faraday::Error::ConnectionFailed
        raise_config_error "Connection refused"
      end
    end
  end
end
