require File.expand_path('../helper.rb', __FILE__)

class GeckoBoardTest < PapertrailServices::TestCase
  def test_logs
    svc = service(:logs, { :token => 'abc', :widget_key => 'def' }, payload)

    http_stubs.post '/v1/send/def' do |env|
      [200, {}, '']
    end

    svc.receive_logs
  end

  def test_failure
    svc = service(:logs, { :token => 'abc', :widget_key => 'def' }, payload)

    http_stubs.post '/v1/send/def' do |env|
      [400, {}, '{ "error":"Bad juju" }']
    end

    assert_raise Service::ConfigurationError do
      svc.receive_logs
    end

    http_stubs.post '/v1/send/def' do |env|
      [500, {}, 'Internal Server Error']
    end

    assert_raise Service::ConfigurationError do
      svc.receive_logs
    end
  end

  def service(*args)
    super Service::GeckoBoard, *args
  end
end
