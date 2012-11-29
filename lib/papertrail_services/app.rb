
# Default the timezone to PST if it isn't set
Time.zone_default = ActiveSupport::TimeZone['Pacific Time (US & Canada)']
module PapertrailServices
  class App < Sinatra::Base
    configure do
      if ENV['SENTRY_KEY'].present?
        Raven.configure do |c|
          c.dsn = ENV['SENTRY_KEY']
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
        $stderr.puts "Error: #{e.class}: #{e.message}"
        $stderr.puts "\t#{e.backtrace.join("\n\t")}"

        if ENV['SENTRY_KEY'].present?
          Raven::Event.capture_exception(e)
        end
      end
    end
  end
end
