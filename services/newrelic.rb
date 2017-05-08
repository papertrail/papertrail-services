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
    # Set an event type (table name)
    event[:eventType] = 'PapertrailAlert'
    # Give the event a name corresponding to the saved search (in case there are multiple alerts sending)
    event[:search_name] = payload[:saved_search][:name]

    # Format the attributes so Insights handles them properly/doesn't reject them: see
    # https://docs.newrelic.com/docs/insights/explore-data/custom-events/insert-custom-events-insights-api#limits

    event[:timestamp] = event[:received_at] = Time.iso8601(event[:received_at]).to_i
    event[:message] = event[:message].truncate(4000, :separator => ' ')
    event[:id] = event[:id].to_s

    event
  end

end