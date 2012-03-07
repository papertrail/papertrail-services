# encoding: utf-8
require 'erb'

class Service::Mail < Service
  def receive_logs
    raise_config_error "No email addresses specified" if settings[:addresses].to_s.empty?

    mail_message.deliver
  end

  def mail_message
    @mail_message ||= begin
      mail = ::Mail.new

      mail.from    'Papertrail <support@papertrailapp.com>'      
      recipients = settings[:addresses].split(/,/).map { |a| a.strip }
      mail.to      recipients
      mail['reply-to'] = recipients.join(', ')
      mail.subject %{[Papertrail] "#{payload[:saved_search][:name]}" search: #{pluralize(payload[:events].length, 'match')}}

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

  def html_email
    erb(unindent(<<-EOF), binding)
      <html>
        <head>
          <title>Papertrail</title>
          <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
        </head>
        <body style="margin:0;background:#f1f1f1;font-family:'Helvetica Neue', helvetica, arial, sans-serif;padding-bottom:30px;">
          <div style="padding:10px 30px;background:#00488F;border-bottom:3px solid #fff;margin:0 0 20px 0;">
            <img src="http://papertrailapp.com/images/papertrail-transparent-white-tiny.png" alt="" />
          </div>
          <div style="background:#fff;border:1px solid #ddd;padding:10px 20px;margin:0 30px;">

          <h3>
            Here's the most recent events matching your "<a href="<%=h payload[:saved_search][:html_search_url] %>"><%= h payload[:saved_search][:name] %></a>" search:
          </h3>

          <div style="font-family:monaco,monospace,courier,'courier new';padding:4px;font-size:11px;border:1px solid #f1f1f1;border-bottom:0;">
            <%- if !payload[:events].empty? -%>
              <%- payload[:events].each do |event| -%>
                <p style="line-height:1.5em;margin:0;padding:2px 0;border-bottom:1px solid #f1f1f1;">
                  <%=h syslog_format(event) %>
                </p>
              <%- end -%>
            <%- else -%>
              <p>No matching events.</p>
            <%- end -%>
          </div>

          <h4>About "<%= h payload[:saved_search][:name] %>":</h4>
          <ul>
            <li>Query: <%= h payload[:saved_search][:query] %></li>
            <li>Search: <%= h payload[:saved_search][:html_search_url] %></li>
          </ul>

          <p>Edit or unsubscribe: <%= h payload[:saved_search][:html_edit_url] %></p>

            <div style="color:#444;font-size:12px;line-height:130%;border-top:1px solid #ddd;margin-top:35px;">
              <p>
                <strong>Can we help?</strong>
                <br />
                support@papertrailapp.com - http://help.papertrailapp.com/
                <br />
                Seven Scale, PO Box 85694, Seattle WA 98145
              </p>
            </div>
          </div>
        </body>
      </html>
    EOF
  end

  def text_email
    erb(unindent(<<-EOF), binding)
      Here's the most recent events matching your "<%= payload[:saved_search][:name] %>" search:

      <%- if !payload[:events].empty? -%>
        <%- payload[:events].each do |event| -%>
      <%=h syslog_format(event) %>
        <%- end -%>
      <%- else -%>
      No matching events.
      <%- end -%>


      About "<%= payload[:saved_search][:name] %>":
         Query: <%= payload[:saved_search][:query] %>
         Search: <%= payload[:saved_search][:html_search_url] %>

      Edit or unsubscribe: <%= payload[:saved_search][:html_edit_url] %>


      --
      Can we help?
      support@papertrailapp.com - http://help.papertrailapp.com/

      Seven Scale, PO Box 85694, Seattle WA 98145
    EOF
  end
end