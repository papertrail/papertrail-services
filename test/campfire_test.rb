require File.expand_path('../helper.rb', __FILE__)

class CampfireTest < PapertrailServices::TestCase
  class MockCampfire
    class Room
      attr_reader :name, :lines, :pastes

      def initialize(name)
        @name  = name
        @lines = []
        @pastes = []
      end

      def speak(line)
        @lines << line
      end

      def paste(lines)
        @pastes << lines
      end
    end

    attr_reader :rooms

    def initialize()
      @rooms = []
    end

    attr_reader :logged_out

    def find_room_by_name(name)
      @rooms << (r=Room.new(name))
      r
    end
  end

  def test_logs
    svc = service(:logs, {"token" => "t", "subdomain" => "s", "room" => "r"}.with_indifferent_access, payload)
    svc.campfire = MockCampfire.new
    svc.receive_logs

    assert_equal 1, svc.campfire.rooms.size
    assert_equal 'r', svc.campfire.rooms.first.name
    assert_equal 1, svc.campfire.rooms.first.lines.size # summary
    assert_equal 1, svc.campfire.rooms.first.pastes.size # logs
  end

  def service(*args)
    super Service::Campfire, *args
  end
end

