require 'active_support/all'
require 'metriks'
require 'scrolls'

# Default the timezone to PST if it isn't set
Time.zone_default = ActiveSupport::TimeZone['Pacific Time (US & Canada)']

module PapertrailServices
  class App < Sinatra::Base
    configure do
      if ENV['HOPTOAD_API_KEY'].present?
        HoptoadNotifier.configure do |config|
          config.api_key = ENV['HOPTOAD_API_KEY']
        end
      end

      if ENV['SENTRY_DSN'].present?
        Raven.configure do |config|
          config.dsn = ENV['SENTRY_DSN']
        end
      end

      if ENV['LIBRATO_EMAIL'].present? && ENV['LIBRATO_TOKEN'].present?
        require 'metriks/librato_metrics_reporter'
        reporter = Metriks::LibratoMetricsReporter.new(ENV['LIBRATO_EMAIL'], ENV['LIBRATO_TOKEN'],
          :source => ENV['DYNO'] || Socket.gethostname, :on_error => proc { |e| report_exception(e) })
        reporter.start

        $metriks_reporters ||= []
        $metriks_reporters << reporter
      end

      Scrolls.init(:exceptions => 'single')
    end

    def self.service(svc)
      post "/#{svc.hook_name}/:event" do
        Scrolls::Log.context[:service]    = svc.hook_name
        Scrolls::Log.context[:request_id] = request['X_REQUEST_ID']

        saved_search_id = nil

        begin
          settings = HashWithIndifferentAccess.new(json_decode(params[:settings]))
          payload  = HashWithIndifferentAccess.new(json_decode(params[:payload]))

          Scrolls::Log.context[:saved_search_id] = saved_search_id = payload[:saved_search][:id] rescue nil

          Metriks.timer("papertrail_services.#{svc.hook_name}").time do
            if svc.receive(params[:event], settings, payload)
              status 200
              ''
            else
              status 404
              status "#{svc.hook_name} Service could not process request"
            end
          end
        rescue Service::ConfigurationError => e
          Metriks.meter("papertrail_services.#{svc.hook_name}.configuration_error").mark

          Scrolls.log_exception({ :from => :service }, e)

          status 400
          e.message
        rescue Net::SMTPSyntaxError, Net::SMTPServerBusy => e
          Metriks.meter("papertrail_services.#{svc.hook_name}.error").mark
          Metriks.meter("papertrail_services.#{svc.hook_name}.error.email").mark

          Scrolls.log_exception({ :from => :service, :saved_search_id => saved_search_id,
            :addresses => settings[:addresses] }, e)

          status 400
        rescue TimeoutError, ::PapertrailServices::Service::TimeoutError => e
          Metriks.meter("papertrail_services.#{svc.hook_name}.error").mark
          Metriks.meter("papertrail_services.#{svc.hook_name}.error.timeout").mark

          Scrolls.log_exception({ :from => :service }, e)

          status 500
          'error'
        rescue Object => e
          Metriks.meter("papertrail_services.#{svc.hook_name}.error").mark
          report_exception(e, :saved_search_id => saved_search_id)
          status 500
          'error'
        ensure
          Scrolls::Log.context = {}
        end
      end

      get '/' do
        'ok'
      end

      def json_decode(value)
        Yajl::Parser.parse(value, :check_utf8 => false)
      end

      def json_encode(value)
        Yajl::Encoder.encode(value)
      end

      def report_exception(e, additional_attributes = {})
        $stderr.puts "#{request.path_info}: Error: #{e.class}: #{e.message}"
        $stderr.puts "\t#{e.backtrace.join("\n\t")}"

        if ENV['HOPTOAD_API_KEY'].present?
          begin
            HoptoadNotifier.notify(e, :parameters => additional_attributes)
          rescue
          end
        end

        if ENV['SENTRY_DSN'].present?
          begin
            Raven::Rack.capture_exception(e, env, :extra => additional_attributes)
          rescue => e
            puts "Sentry exception: #{e.class}: #{e.message}: #{e.backtrace.join("\n\t")}"
          end
        end
      end
    end
  end
end
