require 'aws-sdk'

class Service::CloudWatch < Service

  def metrics_from_counts(counts, max_days = 14)
    counts.map do |time, count|
      timestamp = Time.at(time)
      if timestamp < Time.now - 60 * 60 * 24 * max_days
        raise_config_error "CloudWatch will not accept #{timestamp.iso8601} timestamp; it is more than #{max_days} days old"
      end
      {
        metric_name: settings[:metric_name],
        timestamp: timestamp.iso8601,
        value: count,
      }
    end
  end

  def prepare_post_data(events, size_limit = 8192, max_days = 14)

    counts = event_counts_by_received_at(events)

    metric_data = metrics_from_counts(counts, max_days)

    post_data = {
      namespace: settings[:metric_namespace],
      metric_data: metric_data
    }

    ret = []

    post_json = post_data.to_json

    if post_json.length <= size_limit
      [post_data]
    else
      metric_data.map do |d| # one for each timestamp is as small as this can go
        post_data = {
          namespace: settings[:metric_namespace],
          metric_data: d
        }
        post_json = post_data.to_json
        if post_json.length > size_limit # pathological case
          raise_config_error "Logs exceed CloudWatch payload limit of #{size_limit} bytes"
        end
        post_json
      end
    end
  end

  def receive_logs
    required_settings = [:aws_access_key_id,
                         :aws_secret_access_key,
                         :aws_region,
                         :metric_namespace,
                         :metric_name,
                        ]
    required_settings.each do |setting|
      raise_config_error "Missing required setting #{setting}" if
        settings[setting].to_s.empty?
    end

    if settings[:metric_namespace].present?
      metric_namespace = settings[:metric_namespace]
    else
      metric_namespace = 'Papertrail'
    end

    cloudwatch = AWS::CloudWatch::Client.new(
      region: settings[:aws_region],
      access_key_id: settings[:aws_access_key_id],
      secret_access_key: settings[:aws_secret_access_key],
    )

    post_array = prepare_post_data(payload[:events])

    post_array.each do |post_data|
      resp = cloudwatch.put_metric_data post_data
    end

  end
end
