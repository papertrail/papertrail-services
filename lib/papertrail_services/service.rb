require 'papertrail_services/helpers/logs_helpers'

module PapertrailServices
  class Service
    TIMEOUT = 20

    def self.receive(event, settings, payload)
      svc = new(event, settings, payload)

      # Set the timezone if it exists as a setting
      if settings[:time_zone].present?
        begin
          Time.zone = settings[:time_zone]
        rescue
          # If we couldn't load the timezone, we still want to work
        end
      else
        Time.zone = nil
      end

      # TODO log payload for requests
      #
      # We'll want to test sawlert in noop mode to determine if the payloads
      # are accurate compared with what we're sending from the rails app.
      if payload[:noop_mode]
        return true
      end

      event_method = "receive_#{event}".to_sym
      if svc.respond_to?(event_method)
        Timeout.timeout(TIMEOUT, TimeoutError) do
          svc.send(event_method)
        end

        true
      else
        false
      end
    end

    def self.services
      @services ||= []
    end

    def self.hook_name
      @hook_name ||= begin
        hook = name.dup
        hook.downcase!
        hook.sub! /.*:/, ''
        hook
      end
    end

    def self.inherited(svc)
      PapertrailServices::Service.services << svc
      PapertrailServices::App.service(svc)
      super
    end

    attr_reader :event
    attr_reader :settings
    attr_reader :payload
    attr_writer :http

    def initialize(event = :logs, settings = {}, payload = nil)
      helper_name = "#{event.to_s.capitalize}Helpers"
      if PapertrailServices::Helpers.const_defined?(helper_name)
        @helper = PapertrailServices::Helpers.const_get(helper_name)
        extend @helper
      else
        raise ArgumentError, "Invalid event: #{event.inspect}"
      end

      @event    = event
      @settings = settings
      @payload  = payload || sample_payload
    end

    def http_get(url = nil, params = nil, headers = nil)
      http.get do |req|
        req.url(url)                if url
        req.params.update(params)   if params
        req.headers.update(headers) if headers
        yield req if block_given?
      end
    end

    def http_post(url = nil, body = nil, headers = nil)
      http.post do |req|
        req.url(url)                if url
        req.headers.update(headers) if headers
        req.body = body             if body
        yield req if block_given?
      end
    end

    def http_method(method, url = nil, body = nil, headers = nil)
      http.send(method) do |req|
        req.url(url)                if url
        req.headers.update(headers) if headers
        req.body = body             if body
        yield req if block_given?
      end
    end

    def faraday_options
      options = {
        :timeout => 6,
        :ssl => {
          :ca_file => ca_file,
          :verify_depth => 5
        }
      }
    end

    def http(options = {})
      @http ||= begin
        Faraday.new(faraday_options.merge(options)) do |b|
          b.adapter :net_http_persistent
        end
      end
    end

    def smtp_settings
      {
        :address              => ENV['SMTP_SERVER'],
        :port                 => ENV['SMTP_PORT']           || 25,
        :authentication       => ENV['SMTP_AUTHENTICATION'] || :plain,
        :user_name            => ENV['SMTP_USERNAME']       || ENV['SENDGRID_USERNAME'],
        :password             => ENV['SMTP_PASSWORD']       || ENV['SENDGRID_PASSWORD'],
        :domain               => ENV['SMTP_DOMAIN']         || ENV['SENDGRID_DOMAIN'],
        :enable_starttls_auto => true
      }
    end

    def sample_payload
      @helper.sample_payload
    end

    def raise_config_error(msg = "Invalid configuration")
      raise ConfigurationError, msg
    end

    # Gets the path to the SSL Certificate Authority certs.  These were taken
    # from: http://curl.haxx.se/ca/cacert.pem
    def ca_file
      @ca_file ||= File.expand_path('../../../config/cacert.pem', __FILE__)
    end

    # Optional bulk parameter is needed if the main events array is something
    # other than payload[:events]
    def json_limited(payload, size_limit, bulk = payload[:events])
      ret = payload.to_json

      while ret.length > size_limit
        # This should only run once in the vast majority of cases, but the loop
        # is necessary for pathological inputs
        estimate = 0.9 * size_limit / ret.length
        new_length = (bulk.length * estimate).floor
        bulk.pop bulk.length - new_length
        ret = payload.to_json
      end

      ret
    end

    class TimeoutError < StandardError; end
    class ConfigurationError < StandardError; end
  end
end

::Service = PapertrailServices::Service

Dir[File.expand_path('../../../services/**/*.rb', __FILE__)].each { |service| load service }


