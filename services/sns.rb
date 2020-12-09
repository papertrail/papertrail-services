class Service::SNS < Service
  def receive_logs
    raise_config_error 'Missing AWS Access Key' if settings[:aws_access_key_id].to_s.empty?
    raise_config_error 'Missing AWS Secret Access Key' if settings[:aws_secret_access_key].to_s.empty?
    raise_config_error 'Missing AWS Region' if settings[:aws_region].to_s.empty?
    raise_config_error 'Missing AWS SNS Topic' if settings[:aws_sns_topic_arn].to_s.empty?

    sns_client = Aws::SNS::Client.new(
      region: settings[:aws_region],
      credentials: Aws::Credentials.new(settings[:aws_access_key_id], settings[:aws_secret_access_key]),
      stub_responses: !!ENV['STUB_RESPONSES']
    )
    begin
      payload[:events].each do |event|
        sns_client.publish(topic_arn: settings[:aws_sns_topic_arn], message: syslog_format(event))
      end
    rescue Aws::SNS::Errors::AuthorizationErrorException, Aws::SNS::Errors::NotFoundException => e
      raise Service::ConfigurationError,
        "Error sending to Amazon SNS: #{e.message}"
    rescue Aws::Errors::ServiceError => e
      raise Service::ConfigurationError,
        "Error sending to Amazon SNS (#{e.class.to_s.demodulize})"
    end
  end
end
