# encoding: utf-8

# Initial implementation by Mike Heffner:
#  https://github.com/librato/papertrail_pagerduty_webhook
class Service::Pagerduty < Service
  def post_data(body)
    size_limit = 3.megabytes # PagerDuty specified 3mb as of Aug 2016

    body[:service_key] = settings[:service_key].to_s.strip
    body[:event_type] = 'trigger'

    resp = http_post "https://events.pagerduty.com/generic/2010-04-15/create_event.json", json_limited(body, size_limit, body[:details][:messages])
    unless resp.success?
      error_body = Yajl::Parser.parse(resp.body) rescue nil

      if error_body
        raise_config_error("Unable to send: #{error_body['errors'].join(", ")}")
      else
        puts "pagerduty: #{payload[:saved_search][:id]}: #{resp.status}: #{resp.body}"
      end
    end
  end

  def receive_logs
    events = payload[:events]

    if events.present?
      events_by_incident_key = Hash.new do |h,k|
        h[k] = []
      end

      events.each do |event|
        if settings[:incident_key].present?
          incident_key = settings[:incident_key].gsub('%HOST%', event[:source_name])
        end
        events_by_incident_key[incident_key] << event
      end

      events_by_incident_key.each do |incident_key, events|
        events.sort_by! { |e| e[:id].to_i }
        hosts = events.collect { |e| e[:source_name] }.sort.uniq

        if hosts.length < 5
          description = "#{settings[:description]} (#{hosts.join(', ')})"
        else
          description = "#{settings[:description]} (from #{hosts.length} hosts)"
        end

        body = {
          :description => description,
          :details => {
            :messages => events.collect { |event| syslog_format(event) }
          }
        }

        if incident_key.present?
          body[:incident_key] = incident_key
        end

        min_id, max_id = events.first[:id], events.last[:id]
        base_url = payload[:saved_search][:html_search_url]

        body[:details][:log_start_url] =
          "#{base_url}?centered_on_id=#{payload[:min_id]}"
        body[:details][:log_end_url] =
          "#{base_url}?centered_on_id=#{payload[:max_id]}"

        post_data(body)
      end
    else
      frequency   = frequency_phrase(payload[:frequency])
      search_url  = payload[:saved_search][:html_search_url]
      description = %{#{settings[:description]} found 0 matches #{frequency}}

      body = {
        :description => description,
        :details => {
          :search_url => search_url
        }
      }

      if settings[:incident_key].present?
        body[:incident_key] = settings[:incident_key]
      end

      post_data(body)
    end
  end
end
