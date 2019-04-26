require File.expand_path('../helper.rb', __FILE__)

class AppTest < Minitest::Test

  include Rack::Test::Methods

  def app
    PapertrailServices::App
  end

  def test_root
    get '/'
    assert last_response.ok?
    assert_equal 'ok', last_response.body
  end

  def test_post_event
    Service::AppOptics.any_instance.expects(:receive_logs)
    $stdout.expects(:puts) # keep test output clean
    post '/appoptics/logs', {settings: '', payload: '{"message":"ohno"}'}
    assert last_response.ok?
    assert_equal '', last_response.body
  end

end
