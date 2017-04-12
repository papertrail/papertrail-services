class Service::NewRelic < Service
  def receive_logs
    raise_config_error 'Missing account ID' if settings[:account_id].to_s.empty?
    raise_config_error 'Missing API key' if settings[:insights_api_key].to_s.empty?
    
    post_url = "https://insights-collector.newrelic.com/v1/accounts/#{settings[:account_id]}/events"
    http.headers['Content-Type'] = 'application/json'
    http.headers['X-Insert-Key'] = settings[:insights_api_key]

    
    response = http_post post_url, (format_events(payload[:events])).to_json

    unless response.success?
      puts "new_relic: #{payload[:saved_search][:id]}: #{response.status}: #{response.body}"
      raise_config_error "Could not submit log events to New Relic Insights"
    end
  end
  
  def format_events(events)
    events.each do |event|
      
      # Set an event type (table name) # TODO: make these configurable?
      event[:eventType] = 'PapertrailAlert'
      # Give the event a name corresponding to the saved search (in case there are multiple alerts sending)
      event[:search_name] = payload[:saved_search][:name]
      
      # Format the attributes so Insights handles them properly/doesn't reject them: see
      # https://docs.newrelic.com/docs/insights/explore-data/custom-events/insert-custom-events-insights-api#limits
      
      event[:received_at] = Time.iso8601(event[:received_at]).to_i
      event[:message] = event[:message].truncate(4000, :separator => ' ')
    end
  end
end