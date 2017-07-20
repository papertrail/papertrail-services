# encoding: utf-8
require 'erb'

class Service::Mail < Service
  SEPARATOR = /[,;\s]+/

  def receive_logs
    raise_config_error "No email addresses specified" if settings[:addresses].to_s.empty?

    mail_message.deliver
  end

  def mail_message
    @mail_message ||= begin
      recipients = settings[:addresses].sub(/^#{SEPARATOR}/, '').split(SEPARATOR)

      mail = ::Mail.new
      mail.from 'Papertrail <support@papertrailapp.com>'
      mail.to recipients
      mail['reply-to'] = recipients.join(', ')
      mail['X-Report-Abuse-To'] = 'support@papertrailapp.com'
      mail['List-Unsubscribe'] = "<#{payload[:saved_search][:html_edit_url]}>"
      mail.subject %{[Papertrail] "#{payload[:saved_search][:name]}" alert: #{Pluralize.new('match', :count => payload[:events].length)} (at #{alert_time})}

      text = text_email
      html = html_email

      mail.text_part do
        body text
      end

      mail.html_part do
        content_type 'text/html; charset=UTF-8'
        body html
      end

      mail.delivery_method :smtp, smtp_settings

      mail
    end
  end

  def alert_time
    Time.zone.now.strftime('%F %R')
  end

  def event_count
    payload[:events].length
  end

  def html_email
    erb(unindent(<<-EOF), binding)
      <html>
        <head>
          <title>Papertrail</title>
          <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
          <style type="text/css">
            @media only screen and (max-device-width: 480px) {
              .body {
                padding: 0 10px 5px 10px !important;
              }

              .hdr {
                padding: 10px !important;
              }
            }
          </style>
        </head>
        <body style="margin:0;padding:0;background:#fff;font-family:'Helvetica Neue', helvetica, arial, sans-serif;padding-bottom:30px;">
          <div class="hdr" style="padding:10px 20px;background:#00488F;margin:0;">
            <img src="http://papertrailapp.com/images/pt-logo.png" width="150" alt="Papertrail" />
          </div>
          <div class="body" style="padding:15px 20px;">

          <h3 style="font-weight: normal;">
            <strong><%= Pluralize.new('event', :count => event_count) %></strong>
            matched your <a href="<%=h payload[:saved_search][:html_search_url] %>"><%= h payload[:saved_search][:name] %></a> search
            in the past <%= payload[:frequency] %>.
          </h3>

          <%- if !payload[:events].empty? -%>
          <div style="font-family:monaco,monospace,courier,'courier new';padding:4px;font-size:11px;border:1px solid #f1f1f1;border-bottom:0;">
            <%- payload[:events].each do |event| -%>
              <p style="line-height:1.5em;margin:0;padding:2px 0;border-bottom:1px solid #f1f1f1;">
                <%= html_syslog_format(event, payload[:saved_search][:html_search_url]) %>
              </p>
            <%- end -%>
          </div>
          <%- end -%>

          <h4>About "<%= h payload[:saved_search][:name] %>":</h4>
          <ul>
            <li>Query: <%= h payload[:saved_search][:query] %></li>
            <li>Run search: <a href="<%= payload[:saved_search][:html_search_url] %>"><%= payload[:saved_search][:name] %></a></li>
            <li>Time zone: <%= h Time.zone.name %></li>
            <li><a href="<%= payload[:saved_search][:html_edit_url] %>">Edit or unsubscribe</a></li>
          </ul>

            <div style="color:#444;font-size:12px;line-height:130%;border-top:1px solid #ddd;margin-top:35px;">
              <p>
                <strong>Can we help?</strong>
                <br />
                <a href="mailto:support@papertrailapp.com">support@papertrailapp.com</a> - <a href="http://help.papertrailapp.com/">help.papertrailapp.com</a>
              </p>
            </div>
          </div>
        </body>
      </html>
    EOF
  end

  def text_email
    erb(unindent(<<-EOF), binding)

      <%= Pluralize.new('event', :count => event_count) %> matched your "<%= payload[:saved_search][:name] %>" search in the past <%= payload[:frequency] %>..

      <%- if !payload[:events].empty? -%>
        <%- payload[:events].each do |event| -%>
          <%= syslog_format(event) %>
        <%- end -%>
      <%- end -%>


      About "<%= payload[:saved_search][:name] %>":
         Query: <%= payload[:saved_search][:query] %>
         Time zone: <%= Time.zone.name %>
         Search: <%= payload[:saved_search][:html_search_url] %>

      Edit or unsubscribe: <%= payload[:saved_search][:html_edit_url] %>


      --
      Can we help?
      support@papertrailapp.com - http://help.papertrailapp.com/

      Papertrail Inc., 7171 Southwest Parkway, Austin, TX 78735 USA
    EOF
  end
end
