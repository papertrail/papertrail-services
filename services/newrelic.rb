class Service::NewRelic < Service
  def receive_logs
    # Insights allows 1000 events per batch and 1 MB batch size
    event_limit = 1000    
    size_limit = 1.megabytes
    
    raise_config_error 'Missing account ID' if settings[:account_id].to_s.empty?
    raise_config_error 'Missing API key' if settings[:insights_api_key].to_s.empty?
    
    post_url = "https://insights-collector.newrelic.com/v1/accounts/#{settings[:account_id]}/events"
    http.headers['Content-Type'] = 'application/json'
    http.headers['X-Insert-Key'] = settings[:insights_api_key]

    formatted_events = payload[:events][0,event_limit].collect { |event| format_event(event) }
    
    response = http_post post_url, json_limited(formatted_events, size_limit, formatted_events)

    unless response.success?
      puts "newrelic: #{payload[:saved_search][:id]}: #{response.status}: #{response.body}"
      raise_config_error "Could not submit log events to New Relic Insights"
    end
  end

  def format_event(event)
    # create an event with extra attributes & formats for Insights
    # eventType: table name; search_name: distinguishes events from different searches
    # formats: see https://docs.newrelic.com/docs/insights/explore-data/custom-events/insert-custom-events-insights-api#limits

    formatted_event = {
      :eventType => 'PapertrailAlert',
      :search_name => payload[:saved_search][:name],
      :timestamp => Time.iso8601(event[:received_at]).to_i,
      :received_at => Time.iso8601(event[:received_at]).to_i,
      :display_received_at => event[:display_received_at],
      :id => event[:id].to_s,
      :source_id => event[:source_id].to_s,
      :source_ip => event[:source_ip],
      :source_name => event[:source_name],
      :facility => event[:facility],
      :severity => event[:severity],
      :hostname => event[:hostname],
      :program => event[:program],
      :message => event[:message]
    }

    if event[:message].length >= 4000
      formatted_event[:message] = event[:message][0..4000] + '...'
    else
      formatted_event[:message] = event[:message]
    end

    formatted_event
  end

end