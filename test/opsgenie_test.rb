require File.expand_path('../helper', __FILE__)

class OpsGenieTest < PapertrailServices::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_logs
    svc = service(:logs, { :api_key => 'k' }, payload)

    @stubs.post '/api/v1/json/papertrail' do |env|
      [200, {}, '']
    end

    svc.receive_logs
  end

  def service(*args)
    super Service::OpsGenie, *args
  end
end
