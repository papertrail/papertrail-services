Papertrail Services
===================

Service hooks for [Papertrail][].

Search Alert Service Lifecycle
------------------------------

1. A background job looking for new messages matching a saved search on
   [Papertrail][]
2. If any Search Alerts have been configured it triggers a request to
   `https://<services-server>/<service_name>/logs` with the post data:
   - `params[:settings]`: the options the user specified in the Search Alert configuration
   - `params[:payload]`: the event data for the matched log messages
3. A [sinatra][] app [lib/papertrail_services/app.rb][] decodes the request
   and dispatches it to a registered service if it exists


Writing a Service
-----------------

All services are found in the [services/][] directory. They must have a method
named `receive_logs` that is called when an alert is matched.

The settings are available as a `Hash` in the instance method `settings` and
the event payload is available as a `Hash` in the instance method `payload`.

Helper methods for dealing with basic formatting are available in
[lib/papertrail_services/helpers/logs_helpers.rb][] and also contains a sample
payload.

Tests should accompany all services and are located in the [services/][]
directory.


Sample Service
--------------

Here's a simple service that just counts the number of messages that were
received and posts them to a service.

```ruby
class Service::Sample < Service
  def receive_logs
    count = payload[:events].length

    http_post 'https://sample-service.com/post.json' do |req|
      req.body = {
        settings[:name] => count
      }
    end
  end
end
```

Sample Payload
--------------

This is a sample `payload` that is also available in [lib/papertrail_services/helpers/logs_helpers.rb][].

```ruby
{
  "min_id"=>"31171139124469760", "max_id"=>"31181206313902080", "reached_record_limit" => true,
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
    {"source_ip"=>"127.0.0.1", "display_received_at"=>"Jul 22 14:50:01", "source_name"=>"alien", "facility"=>"Cron", "id"=>31181206313902080, "hostname"=>"alien", "program"=>"CROND", "message"=>"(root) CMD (/usr/lib/sa/sa1 -S DISK 1 1)", "severity"=>"Info", "source_id"=>6, "received_at"=>"2011-07-22T14:50:01-07:00"}
  ]
}
```

More info about Papertrail Webhooks
-----------------------------------

If you would like more info about how our webhooks work, head over to our
[webhooks documentation][].


Contributing
------------

Once you've made your great commits:

1. [Fork][fk] `papertrail_services`
2. Create a topic branch — `git checkout -b my_branch`
3. Commit the changes without changing the Rakefile or other files unrelated to your enhancement.
4. Push to your branch — `git push origin my_branch`
5. Create a Pull Request or an [Issue][is] with a link to your branch
6. That's it!


Credits
-------

This project is heavily influenced in spirit and code by [github-services][].
We love what GitHub has done for all of us and what they have demonstrated
can be accomplished with community involvement.

We thank them for everything they've done for all of us.

[lib/papertrail_services/app.rb]: https://github.com/papertrail/papertrail-services/blob/master/lib/papertrail_services/app.rb
[services/]: https://github.com/papertrail/papertrail-services/tree/master/services
[lib/papertrail_services/helpers/logs_helpers.rb]: https://github.com/papertrail/papertrail-services/blob/master/lib/papertrail_services/helpers/logs_helpers.rb
[test/]: https://github.com/papertrail/papertrail-services/tree/master/test
[github-services]: https://github.com/github/github-services/
[sinatra]: http://www.sinatrarb.com/
[fk]: https://help.github.com/articles/fork-a-repo
[is]: https://github.com/papertrail/papertrail_services/issues/
[Papertrail]: http://papertrailapp.com/
[webhooks documentation]: http://help.papertrailapp.com/kb/how-it-works/web-hooks