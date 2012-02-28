# encoding: utf-8
require File.expand_path('../helper', __FILE__)

class HipchatTest < PapertrailServices::TestCase
  class MockHipChat
    attr_reader :entries, :rooms
    def rooms_message(room_id, from, message, notify = 0, color = 'yellow')
      @rooms ||= {}
      @rooms[room_id] ||= []
      @rooms[room_id] << message
    end
  end

  def test_logs
    svc = service(:logs, {'token' => 't', 'room_id' => 'r'}.with_indifferent_access, payload)
    svc.hipchat = MockHipChat.new
    svc.receive_logs

    rooms = svc.hipchat.rooms
    assert_equal 1, rooms.size

    msgs = rooms['r']
    assert_equal 2, msgs.size

    #NOTE: utf-8 dash
    expected = %{"cron" search found 5 matches — https://papertrailapp.com/searches/392}
    assert_equal expected, msgs.first

    expected =<<-'EOF'.lines.map(&:strip).join
      <pre>Jul 22 14:10:01 alien CROND: (root) CMD (/usr/lib/sa/sa1 -S DISK 1 1)</pre>
      <br />
      <pre>Jul 22 14:20:01 alien CROND: (root) CMD (/usr/lib/sa/sa1 -S DISK 1 1)</pre>
      <br />
      <pre>Jul 22 14:30:01 alien CROND: (root) CMD (/usr/lib/sa/sa1 -S DISK 1 1)</pre>
      <br />
      <pre>Jul 22 14:40:01 alien CROND: (root) CMD (/usr/lib/sa/sa1 -S DISK 1 1)</pre>
      <br />
      <pre>Jul 22 14:50:01 alien CROND: (root) CMD (/usr/lib/sa/sa1 -S DISK 1 1)</pre>
      EOF
    assert_equal expected, msgs.last
  end

  def service(*args)
    super Service::HipChat, *args
  end
end
