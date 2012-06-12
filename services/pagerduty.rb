# encoding: utf-8

# Initial implementation by Mike Heffner:
#  https://github.com/librato/papertrail_pagerduty_webhook
class Service::Pagerduty < Service
  def receive_logs
    events_by_incident_key = Hash.new do |h,k|
      h[k] = []
    end

    payload[:events].each do |event|
      if settings[:incident_key].present?
        incident_key = settings[:incident_key].gsub('%HOST%', event[:source_name])
      end
      events_by_incident_key[incident_key] << event
    end

    events_by_incident_key.each do |incident_key, events|
      events.sort_by! { |e| e[:id].to_i }
      hosts = events.collect { |e| e[:source_name] }.sort.uniq

      body = {
        :service_key => settings[:service_key],
        :event_type => 'trigger',
        :description => "#{settings[:description]} (#{hosts.join(', ')})",
        :details => {
          :messages => events.collect { |event| syslog_format(event) }
        }
      }

      if incident_key.present?
        body[:incident_key] = incident_key
      end

      min_id, max_id = events.first[:id], events.last[:id]
      base_url = settings[:base_url].present? ? settings[:base_url] : 'https://papertrailapp.com/events'

      body[:details][:log_start_url] =
        "#{base_url}?centered_on_id=#{payload[:min_id]}"
      body[:details][:log_end_url] =
        "#{base_url}?centered_on_id=#{payload[:max_id]}"

      http_post "https://events.pagerduty.com/generic/2010-04-15/create_event.json", body.to_json
    end
  end
end