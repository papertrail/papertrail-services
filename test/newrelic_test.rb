require File.expand_path('../helper', __FILE__)

class NewRelicTest < PapertrailServices::TestCase
  def test_config
    svc = service(:logs, {}.with_indifferent_access, payload)
    assert_raises(PapertrailServices::Service::ConfigurationError) { svc.receive_logs }

    svc = service(:logs, { 'insights_api_key' => "foobar" }.with_indifferent_access, payload)
    assert_raises(PapertrailServices::Service::ConfigurationError) { svc.receive_logs }

    svc = service(:logs, { 'account_id' => "1929219" }.with_indifferent_access, payload)
    assert_raises(PapertrailServices::Service::ConfigurationError) { svc.receive_logs }
  end
  
  def test_logs
    svc = service(:logs, service_settings, payload)

    http_stubs.post "/v1/accounts/531007/events" do |env|
      [200, {}, ""]
    end

    svc.receive_logs
  end
  
  def test_size_limit
    assert(payload.to_json.length > 1400, 'Test requires larger sample payload')
    
    svc = service(:logs, service_settings, payload)
    limited_payload = svc.json_limited(payload, 1400)
    assert(limited_payload.length <= 1400)

    http_stubs.post "/v1/accounts/531007/events" do |env|
      [200, {}, ""]
    end
    svc.receive_logs
  end

  def test_event_format
    local_payload = {
          "min_id"=>"31171139124469760", "max_id"=>"31181206313902080", "reached_record_limit"=>true,
          "saved_search" => {
            "name" => "cron",
            "query" => "cron",
            "id" => 392,
            "html_edit_url" => "https://papertrailapp.com/searches/392/edit",
            "html_search_url" => "https://papertrailapp.com/searches/392"
          },
          "events"=>[
            {"source_ip"=>"127.0.0.1", "display_received_at"=>"Jul 22 14:10:01", "source_name"=>"alien", "facility"=>"Cron", "id"=>31171139124469760, "hostname"=>"alien", "program"=>"CROND", "message"=>long_message, "severity"=>"Info", "source_id"=>6, "received_at"=>"2011-07-22T14:10:01-07:00"},
            {"source_ip"=>"127.0.0.1", "display_received_at"=>"Jul 22 14:10:01", "source_name"=>"alien", "facility"=>"Cron", "id"=>31173655908196352, "hostname"=>"alien", "program"=>"CROND", "message"=>"(root) CMD (/usr/lib/sa/sa1 -S DISK 1 1)", "severity"=>"Info", "source_id"=>6, "received_at"=>"2011-07-22T14:10:10-07:00"},
            {"source_ip"=>"127.0.0.1", "display_received_at"=>"Jul 22 14:30:01", "source_name"=>"alien", "facility"=>"Cron", "id"=>31176172704505856, "hostname"=>"alien", "program"=>"CROND", "message"=>"(root) CMD (/usr/lib/sa/sa1 -S DISK 1 1)", "severity"=>"Info", "source_id"=>6, "received_at"=>"2011-07-22T14:30:01-07:00"},
            {"source_ip"=>"127.0.0.1", "display_received_at"=>"Jul 22 14:40:01", "source_name"=>"alien", "facility"=>"Cron", "id"=>31178689513398272, "hostname"=>"alien", "program"=>"CROND", "message"=>"(root) CMD (/usr/lib/sa/sa1 -S DISK 1 1)", "severity"=>"Info", "source_id"=>6, "received_at"=>"2011-07-22T14:40:01-07:00"},
            {"source_ip"=>"127.0.0.1", "display_received_at"=>"Jul 22 14:50:01", "source_name"=>"lullaby", "facility"=>"Cron", "id"=>31181206313902080, "hostname"=>"lullaby", "program"=>"CROND", "message"=>"(root) CMD (/usr/lib/sa/sa1 -S DISK 1 1)", "severity"=>"Info", "source_id"=>6, "received_at"=>"2011-07-22T14:50:01-07:00"}
          ]
        }.with_indifferent_access
    svc = service(:logs, service_settings, local_payload)

    http_stubs.post "/v1/accounts/531007/events" do |env|
      
      body = JSON(env[:body])
        
      assert(body[0]['eventType'] == 'PapertrailAlert', "Did not find expected event type key")
      assert(body[0]['search_name'] == 'cron', "Did not find expected search name key")
      assert(body[0]['message'].bytesize < 4000, "Included a message that is too long")
      assert(body[0]['received_at'].to_i == body[0]['received_at'], "received_at is not a number")
      assert(body[0]['id'].to_s == body[0]['id'], "id is not a string")
      assert(body[0]['source_id'].to_s == body[0]['source_id'], "source_id is not a string")

      [200, {}, ""]
      
    end
    svc.receive_logs
  end
  
  # Possible TODO: Test that only 1000 events are sent?
    
  def service(*args)
    super Service::NewRelic, *args
  end
  
  def service_settings
    { 'insights_api_key' => '9872--3042dtshN3oen', 
      'account_id' => '531007' }.with_indifferent_access
  end
  
  def long_message
    "Chapter 1  It is a truth universally acknowledged, that a single man in possession of a good fortune, must be in want of a wife.  However little known the feelings or views of such a man may be on his first entering a neighbourhood, this truth is so well fixed in the minds of the surrounding families, that he is considered the rightful property of some one or other of their daughters.  'My dear Mr. Bennet,' said his lady to him one day, 'have you heard that Netherfield Park is let at last?'  Mr. Bennet replied that he had not.  'But it is,' returned she; 'for Mrs. Long has just been here, and she told me all about it.'  Mr. Bennet made no answer.  'Do you not want to know who has taken it?' cried his wife impatiently.  '_You_ want to tell me, and I have no objection to hearing it.'  This was invitation enough.  'Why, my dear, you must know, Mrs. Long says that Netherfield is taken by a young man of large fortune from the north of England; that he came down on Monday in a chaise and four to see the place, and was so much delighted with it, that he agreed with Mr. Morris immediately; that he is to take possession before Michaelmas, and some of his servants are to be in the house by the end of next week.'  'What is his name?'  'Bingley.'  'Is he married or single?'  'Oh!  Single, my dear, to be sure!  A single man of large fortune; four or five thousand a year.  What a fine thing for our girls!'  'How so?  How can it affect them?'  'My dear Mr. Bennet,' replied his wife, 'how can you be so tiresome!  You must know that I am thinking of his marrying one of them.'  'Is that his design in settling here?'  'Design!  Nonsense, how can you talk so!  But it is very likely that he _may_ fall in love with one of them, and therefore you must visit him as soon as he comes.'  'I see no occasion for that.  You and the girls may go, or you may send them by themselves, which perhaps will be still better, for as you are as handsome as any of them, Mr. Bingley may like you the best of the party.'  'My dear, you flatter me.  I certainly _have_ had my share of beauty, but I do not pretend to be anything extraordinary now. When a woman has five grown-up daughters, she ought to give over thinking of her own beauty.'  'In such cases, a woman has not often much beauty to think of.'  'But, my dear, you must indeed go and see Mr. Bingley when he comes into the neighbourhood.'  'It is more than I engage for, I assure you.'  'But consider your daughters.  Only think what an establishment it would be for one of them.  Sir William and Lady Lucas are determined to go, merely on that account, for in general, you know, they visit no newcomers.  Indeed you must go, for it will be impossible for _us_ to visit him if you do not.'  'You are over-scrupulous, surely.  I dare say Mr. Bingley will be very glad to see you; and I will send a few lines by you to assure him of my hearty consent to his marrying whichever he chooses of the girls; though I must throw in a good word for my little Lizzy.'  'I desire you will do no such thing.  Lizzy is not a bit better than the others; and I am sure she is not half so handsome as Jane, nor half so good-humoured as Lydia.  But you are always giving _her_ the preference.'  'They have none of them much to recommend them,' replied he; 'they are all silly and ignorant like other girls; but Lizzy has something more of quickness than her sisters.'  'Mr. Bennet, how _can_ you abuse your own children in such a way?  You take delight in vexing me.  You have no compassion for my poor nerves.'  'You mistake me, my dear.  I have a high respect for your nerves.  They are my old friends.  I have heard you mention them with consideration these last twenty years at least.'  'Ah, you do not know what I suffer.'  'But I hope you will get over it, and live to see many young men of four thousand a year come into the neighbourhood.'  'It will be no use to us, if twenty such should come, since you will not visit them.'  'Depend upon it, my dear, that when there are twenty, I will visit them all.'  Mr. Bennet was so odd a mixture of quick parts, sarcastic humour, reserve, and caprice, that the experience of three-and-twenty years had been insufficient to make his wife understand his character.  _Her_ mind was less difficult to develop.  She was a woman of mean understanding, little information, and uncertain temper.  When she was discontented, she fancied herself nervous. The business of her life was to get her daughters married; its solace was visiting and news."
  end
  
end