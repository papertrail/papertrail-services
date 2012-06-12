require File.expand_path('../helper', __FILE__)

class PagerdutyTest < PapertrailServices::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_logs
    svc = service(:logs, { :service_key => 'k' }, payload)

    @stubs.post '/generic/2010-04-15/create_event.json' do |env|
      [200, {}, '']
    end

    svc.receive_logs
  end

  def test_logs_with_incident_key
    svc = service(:logs, { :service_key => 'k', :incident_key => '%HOST%/PAPERTRAIL' }, payload)

    @stubs.post '/generic/2010-04-15/create_event.json' do |env|
      [200, {}, '']
    end

    svc.receive_logs
  end


  def service(*args)
    super Service::Pagerduty, *args
  end
end