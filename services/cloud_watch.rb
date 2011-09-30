class Service::CloudWatch < Service
  attr_writer :acw
  
  def receive_logs
    data_points = prepare(payload[:events], settings[:metric_name], settings[:regex])
    return if data_points.empty?

    if settings[:metric_namespace].present?
      metric_namespace = settings[:metric_namespace]
    else
      metric_namespace = 'Papertrail'
    end
    
    acw.put_metric_data(:namespace => metric_namespace, :data => data_points)
  end

  def acw
    @acw ||= RightAws::AcwInterface.new(settings[:aws_access_key_id], settings[:aws_secret_access_key])
  end
  
  def prepare(events, name, regex)
    unless regex.present?
      # count all events as a single data point
      return [{ 
        :metric_name => name,
        :value => events.length,
        :timestamp => Time.now.utc.strftime('%FT%XZ')
      }]
    end

    extract_data_points(name, events, Regexp.new(regex))
  end
  
  def extract_data_points(name, events, regex)
    data_points = []
          
    events.each do |event|
      value = nil

      match_data = event[:message].match(regex)
      # does not match event
      next unless match_data
  
      # use extracted value or 1 (no regex backreference provided)
      value = match_data[1] ? match_data[1].to_i : 1
  
      data_points << { 
        :metric_name => name,
        :value => value,
        :timestamp => event[:received_at]
      } if value
    end
    
    data_points
  end
end