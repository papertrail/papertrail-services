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
            {"source_ip"=>"127.0.0.1", "display_received_at"=>"Jul 22 14:10:01", "source_name"=>"alien", "facility"=>"Cron", "id"=>31173655908196352, "hostname"=>"alien", "program"=>"CROND", "message"=>"(root) CMD (/usr/lib/sa/sa1 -S DISK 1 1)", "severity"=>"Info", "source_id"=>6, "received_at"=>"2011-07-22T14:10:10-07:00"},
            {"source_ip"=>"127.0.0.1", "display_received_at"=>"Jul 22 14:30:01", "source_name"=>"alien", "facility"=>"Cron", "id"=>31176172704505856, "hostname"=>"alien", "program"=>"CROND", "message"=>"(root) CMD (/usr/lib/sa/sa1 -S DISK 1 1)", "severity"=>"Info", "source_id"=>6, "received_at"=>"2011-07-22T14:30:01-07:00"},
            {"source_ip"=>"127.0.0.1", "display_received_at"=>"Jul 22 14:40:01", "source_name"=>"alien", "facility"=>"Cron", "id"=>31178689513398272, "hostname"=>"alien", "program"=>"CROND", "message"=>"(root) CMD (/usr/lib/sa/sa1 -S DISK 1 1)", "severity"=>"Info", "source_id"=>6, "received_at"=>"2011-07-22T14:40:01-07:00"},
            {"source_ip"=>"127.0.0.1", "display_received_at"=>"Jul 22 14:50:01", "source_name"=>"lullaby", "facility"=>"Cron", "id"=>31181206313902080, "hostname"=>"lullaby", "program"=>"CROND", "message"=>"(root) CMD (/usr/lib/sa/sa1 -S DISK 1 1)", "severity"=>"Info", "source_id"=>6, "received_at"=>"2011-07-22T14:50:01-07:00"}
          ]
        }.with_indifferent_access
      end

      def self.sample_counts_payload
        {
          "min_id"=>"31171139124469760", "max_id"=>"31181206313902080", "reached_record_limit"=>true,
          "saved_search" => {
            "name" => "cron",
            "query" => "cron",
            "id" => 392,
            "html_edit_url" => "https://papertrailapp.com/searches/392/edit",
            "html_search_url" => "https://papertrailapp.com/searches/392"
          },
          "counts"=>[
            {"source_name"=>"alien",
             "source_id"=>6,
             "timeseries"=>{
               "1311369001"=>1,
               "1311369010"=>1,
               "1311370201"=>1,
               "1311370801"=>1,
             }},
            {"source_name"=>"lullaby",
             "source_id"=>7,
             "timeseries"=>{
               "1311371401"=>1
             }}
          ]
        }.with_indifferent_access
      end

      def syslog_format(message, maximum_length = nil)
        time = Time.zone.at(Time.iso8601(message[:received_at]))

        s = "#{time.strftime('%b %d %X')} #{message[:source_name]} #{message[:program]}: "
        if maximum_length && message[:message]
          truncate_message_at = [ 0, maximum_length - s.length - 1 ].max
          s << message[:message][0..truncate_message_at]
        else
          s << message[:message]
        end
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
    end

    module CountsHelpers
      include LogsHelpers
    end
  end
end
