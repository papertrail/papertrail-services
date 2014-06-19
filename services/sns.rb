class Service::SNS < Service
  def receive_logs
    sns = AWS::SNS.new(
    :access_key_id => settings[:aws_access_key_id],
    :secret_access_key => settings[:aws_secret_access_key],
    :region => settings[:aws_region])
    topic = sns.topics[settings[:aws_sns_topic_arn]]

    payload[:events].each do |event|
      topic.publish(event)
    end
  end
end
