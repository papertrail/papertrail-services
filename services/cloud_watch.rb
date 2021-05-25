require 'aws-sdk'

class Service::CloudWatch < Service

  def prepare_post_data(events, metrics_per_request = 20, max_days = 14)
    counts = event_counts_by_received_at(events)

    metric_data = counts.map do |time, count|
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

    if settings[:metric_namespace].present?
      metric_namespace = settings[:metric_namespace]
    else
      metric_namespace = 'Papertrail'
    end

    metric_data.each_slice(metrics_per_request).map do |metric_data_slice|
      {
        namespace: metric_namespace,
        metric_data: metric_data_slice
      }
    end
  end

  def receive_logs
    required_settings = [:aws_access_key_id,
                         :aws_secret_access_key,
                         :aws_region,
                         :metric_name,
                        ]
    required_settings.each do |setting|
      raise_config_error "Missing required setting #{setting}" if
        setting.to_s.empty?
    end

    cloudwatch = AWS::CloudWatch::Client.new(
      region: settings[:aws_region],
      access_key_id: settings[:aws_access_key_id],
      secret_access_key: settings[:aws_secret_access_key],
    )

    post_array = prepare_post_data(payload[:events])

    begin
      post_array.each do |post_data|
        resp = cloudwatch.put_metric_data post_data
      end
    rescue AWS::CloudWatch::Errors::AccessDenied,
           AWS::CloudWatch::Errors::InvalidClientTokenId => e

      raise Service::ConfigurationError,
        "Error sending to Amazon Cloudwatch: #{e.message}"
    end

  end
end
