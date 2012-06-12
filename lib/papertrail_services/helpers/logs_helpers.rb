require 'tilt'

module PapertrailServices
  module Helpers
    module LogsHelpers
      def self.sample_payload
        {
          "min_id"=>"31171139124469760", "max_id"=>"31181206313902080", "reached_record_limit"=>true,
          "saved_search" => {
            "name" => "cron",
            "query" => "cron",
            "id" => 392,
            "html_edit_url" => "https://papertrailapp.com/searches/392/edit",
            "html_search_url" => "https://papertrailapp.com/searches/392"
          },
          "events"=>[
            {"source_ip"=>"127.0.0.1", "display_received_at"=>"Jul 22 14:10:01", "source_name"=>"alien", "facility"=>"Cron", "id"=>31171139124469760, "hostname"=>"alien", "program"=>"CROND", "message"=>"(root) CMD (/usr/lib/sa/sa1 -S DISK 1 1)", "severity"=>"Info", "source_id"=>6, "received_at"=>"2011-07-22T14:10:01-07:00"}, 
            {"source_ip"=>"127.0.0.1", "display_received_at"=>"Jul 22 14:20:01", "source_name"=>"alien", "facility"=>"Cron", "id"=>31173655908196352, "hostname"=>"alien", "program"=>"CROND", "message"=>"(root) CMD (/usr/lib/sa/sa1 -S DISK 1 1)", "severity"=>"Info", "source_id"=>6, "received_at"=>"2011-07-22T14:20:01-07:00"}, 
            {"source_ip"=>"127.0.0.1", "display_received_at"=>"Jul 22 14:30:01", "source_name"=>"alien", "facility"=>"Cron", "id"=>31176172704505856, "hostname"=>"alien", "program"=>"CROND", "message"=>"(root) CMD (/usr/lib/sa/sa1 -S DISK 1 1)", "severity"=>"Info", "source_id"=>6, "received_at"=>"2011-07-22T14:30:01-07:00"}, 
            {"source_ip"=>"127.0.0.1", "display_received_at"=>"Jul 22 14:40:01", "source_name"=>"alien", "facility"=>"Cron", "id"=>31178689513398272, "hostname"=>"alien", "program"=>"CROND", "message"=>"(root) CMD (/usr/lib/sa/sa1 -S DISK 1 1)", "severity"=>"Info", "source_id"=>6, "received_at"=>"2011-07-22T14:40:01-07:00"}, 
            {"source_ip"=>"127.0.0.1", "display_received_at"=>"Jul 22 14:50:01", "source_name"=>"lullaby", "facility"=>"Cron", "id"=>31181206313902080, "hostname"=>"lullaby", "program"=>"CROND", "message"=>"(root) CMD (/usr/lib/sa/sa1 -S DISK 1 1)", "severity"=>"Info", "source_id"=>6, "received_at"=>"2011-07-22T14:50:01-07:00"}
          ]
        }.with_indifferent_access
      end

      def syslog_format(message)
        "#{Time.zone.parse(message[:received_at]).strftime('%b %d %X')} #{message[:source_name]} #{message[:program]}: #{message[:message]}"
      end
      
      def erb(template, target_binding)
        ERB.new(template, nil, '-').result(target_binding)
      end

      def h(text)
        ERB::Util.h(text)
      end

      def unindent(string)
        indentation = string[/\A\s*/]
        string.strip.gsub(/^#{indentation}/, "") + "\n"
      end

      def pluralize(count, singular, plural = nil)
        "#{count || 0} " + ((count == 1 || count =~ /^1(\.0+)?$/) ? singular : (plural || singular.pluralize))
      end
    end
  end
end