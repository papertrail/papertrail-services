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

    incident_id = settings[:aws_sns_incident_id] || ""

    topic = sns.topics[settings[:aws_sns_topic_arn]]

    payload[:events].each do |event|
      topic.publish({ :default => event, :incident_id => incident_id }.to_json)
    end
  end
end
