source 'https://rubygems.org'

gem 'sinatra'
gem 'activesupport', '~> 3.0', :require => 'active_support'
gem 'yajl-ruby', '~> 1.4.1', :require => [ 'yajl', 'yajl/json_gem' ]
gem 'faraday'
gem 'tzinfo', '~> 0.3.53'
gem 'net-http-persistent'

gem 'scrolls'

gem 'metriks'
gem 'metriks-librato_metrics'
gem 'newrelic_rpm'

gem "sentry-raven"

gem 'json', '~> 1.8'
gem 'eventmachine', '~> 1.2'

# service: mail
gem 'mail', '~> 2.6.6'

# service :campfire
gem 'tinder', '~> 1.4'

# service :hipchat
gem 'hipchat-api'

# service :libratometrics
gem 'librato-metrics', '~> 1.0.1', :require => "librato/metrics"

# service :appoptics
gem 'appoptics-api-ruby', :git => 'https://github.com/appoptics/appoptics-api-ruby',
  :ref => '23fe88a', :require => "appoptics/metrics"

# service :aws-sns
gem 'aws-sdk', '~> 1.6'

group :development do
  gem 'foreman'
end

group :building do
  gem 'rake'
end

group :production do
  # Use unicorn as the web server
  gem 'unicorn', '~> 5.5'

  gem 'puma'
end

group :test do
  gem 'rack-test'
  gem 'minitest'
  gem 'mocha', :require => false
end
