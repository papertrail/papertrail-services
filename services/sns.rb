class Service::SNS < Service
  def receive_logs
    raise_config_error 'Missing AWS Access Key' if settings[:aws_access_key_id].to_s.empty?
    raise_config_error 'Missing AWS Secret Access Key' if settings[:aws_secret_access_key].to_s.empty?
    raise_config_error 'Missing AWS Region' if settings[:aws_region].to_s.empty?
    raise_config_error 'Missing AWS SNS Topic' if settings[:aws_sns_topic_arn].to_s.empty?

    sns = AWS::SNS.new(
      :access_key_id => settings[:aws_access_key_id],
      :secret_access_key => settings[:aws_secret_access_key],
      :region => settings[:aws_region])

    topic = sns.topics[settings[:aws_sns_topic_arn]]

    begin
      payload[:events].each do |event|
        topic.publish(event.merge({
          :default => syslog_format(event)
        }))
      end
    rescue AWS::SNS::Errors::AuthorizationError, AWS::SNS::Errors::NotFound => e
      raise Service::ConfigurationError,
        "Error sending to Amazon SNS: #{e.message}"
    rescue AWS::SNS::Errors::ServiceError => e
      raise Service::ConfigurationError,
        "Error sending to Amazon SNS (#{e.class.to_s.demodulize})"
    end
  end
end
