require File.expand_path('../helper.rb', __FILE__)

class AppTest < MiniTest::Unit::TestCase

  include Rack::Test::Methods

  def app
    PapertrailServices::App
  end

  def test_post_event
    Service::AppOptics.any_instance.expects(:receive_logs)
    post '/appoptics/logs', {settings: '', payload: '{"message":"ohno"}'}
    assert last_response.ok?
    assert_equal '', last_response.body
  end

end
