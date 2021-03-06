# encoding: utf-8
require File.expand_path('../helper.rb', __FILE__)

class HipChatTest < PapertrailServices::TestCase
  include PapertrailServices::Helpers::LogsHelpers

  class MockHipChat
    attr_reader :entries, :rooms
    def rooms_message(room_id, from, message, notify = 0, color = 'yellow')
      @rooms ||= {}
      @rooms[room_id] ||= []
      @rooms[room_id] << message
      HTTParty::Response.new(nil, OpenStruct.new(:body => {}, :code => 200), proc {})
    end
  end

  def test_logs
    rooms = get_chats(payload)
    assert_equal 1, rooms.size

    msgs = rooms['r']
    assert_equal 2, msgs.size

    #NOTE: utf-8 dash
    expected = %{"cron" search found 5 matches in the past minute — <a href=\"https://papertrailapp.com/searches/392\">https://papertrailapp.com/searches/392</a>}
    assert_equal expected, msgs.first

    expected =<<-'EOF'.lines.map(&:lstrip).join
      Jul 22 14:10:01 alien CROND: (root) CMD (/usr/lib/sa/sa1 -S DISK 1 1)
      Jul 22 14:10:10 alien CROND: (root) CMD (/usr/lib/sa/sa1 -S DISK 1 1)
      Jul 22 14:30:01 alien CROND: (root) CMD (/usr/lib/sa/sa1 -S DISK 1 1)
      Jul 22 14:40:01 alien CROND: (root) CMD (/usr/lib/sa/sa1 -S DISK 1 1)
      Jul 22 14:50:01 lullaby CROND: (root) CMD (/usr/lib/sa/sa1 -S DISK 1 1)
      EOF
    expected = "<pre>\n#{expected}</pre>"
    assert_equal expected, msgs.last
  end

  def test_no_entries
    rooms = get_chats(payload.dup.merge(:events => []))
    assert_equal 1, rooms.size
    msgs = rooms['r']
    expected = %{"cron" search found 0 matches in the past minute — <a href=\"https://papertrailapp.com/searches/392\">https://papertrailapp.com/searches/392</a>}
    assert_equal [expected], msgs
  end

  def test_escaping
    rooms = get_chats(payload.dup.merge(:events => [{
      :message => '<pre>escaped<br/></pre>',
      :program => 'irb',
      :source_name => 'host1',
      :display_received_at => '2012-02-28',
      :received_at => '2012-02-28T14:20:01-07:00'
    }]))

    assert_equal 1, rooms.size

    msgs = rooms['r']
    assert_equal 2, msgs.size

    #NOTE: utf-8 dash
    expected = %{"cron" search found 1 match in the past minute — <a href=\"https://papertrailapp.com/searches/392\">https://papertrailapp.com/searches/392</a>}
    assert_equal expected, msgs.first

    expected = 'Feb 28 13:20:01 host1 irb: &lt;pre&gt;escaped&lt;br/&gt;&lt;/pre&gt;'
    expected = "<pre>\n#{expected}\n</pre>"
    assert_equal expected, msgs.last
  end

  def test_bulk_logs
    entry = { :message => 'msg0123456789',
      :program => 'abcdef',
      :source_name => 'ABCD',
      :display_received_at => '2012-02-28',
      :received_at => '2012-02-28T14:20:01-07:00' }

    line_length = "#{syslog_format(entry)}\n".size
    formatting = "<pre>\n\n</pre>"
    lines_in_block = (5000 - formatting.size) / line_length
    events = [entry] * lines_in_block
    assert_equal 1+1, get_chats(payload.dup.merge(:events => events))['r'].size
    assert_equal 1+2, get_chats(payload.dup.merge(:events => events * 2))['r'].size
    assert_equal 1+3, get_chats(payload.dup.merge(:events => events * 3))['r'].size
  end

  def get_chats(custom_payload)
    settings = {'token' => 't', 'room_id' => 'r'}
    svc = service(:logs, settings.with_indifferent_access, custom_payload)
    svc.hipchat = MockHipChat.new
    svc.receive_logs
    svc.hipchat.rooms
  end

  def service(*args)
    super Service::HipChat, *args
  end
end
