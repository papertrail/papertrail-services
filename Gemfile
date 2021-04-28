source 'https://rubygems.org'
ruby "2.6.3"

gem 'rack', '1.6.13'
gem 'nokogiri', '1.10.9'

gem 'sinatra', '~> 1.4.7'
gem 'unicorn', '~> 5.5'
gem 'activesupport', '~> 5.2.3', :require => 'active_support'
gem 'yajl-ruby', '~> 1.4.1', :require => [ 'yajl', 'yajl/json_gem' ]
gem 'net-http-persistent'

gem 'scrolls'

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
gem 'aws-sdk-sns', '~> 1'
gem 'aws-sdk-cloudwatch', '~> 1'

group :development do
  gem 'foreman'
end

group :building do
  gem 'rake', '12.3.3'
end

group :test do
  gem 'rack-test'
  gem 'mocha', '~> 1.8', :require => false
  gem 'minitest-ci'
end
