require 'active_support/all'

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
    end

    def self.service(svc)
      post "/#{svc.hook_name}/:event" do
        begin
          settings = HashWithIndifferentAccess.new(json_decode(params[:settings]))
          payload  = HashWithIndifferentAccess.new(json_decode(params[:payload]))

          if svc.receive(:logs, settings, payload)
            status 200
            ''
          else
            status 404
            status "#{svc.hook_name} Service could not process request"
          end
        rescue Service::ConfigurationError => e
          status 400
          e.message
        rescue Yajl::ParseError => e
          status 422
          status "Could not parse settings or payload"
          'error'
        rescue Object => e
          report_exception(e)
          status 500
          'error'
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

      def report_exception(e)
        $stderr.puts "#{request.path_info}: Error: #{e.class}: #{e.message}"
        $stderr.puts "\t#{e.backtrace.join("\n\t")}"

        if ENV['HOPTOAD_API_KEY'].present?
          begin
            HoptoadNotifier.notify(e)
          rescue
          end
        end

        if ENV['SENTRY_DSN'].present?
          begin
            if evt = Raven::Event.capture_rack_exception(e, env)
              Raven.send(evt)
            end
          rescue => e
            puts "Sentry exception: #{e.class}: #{e.message}: #{e.backtrace.join("\n\t")}"
          end
        end
      end
    end
  end
end
