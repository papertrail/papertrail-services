source :rubygems

gem 'sinatra'
gem 'activesupport', '~> 2.3', :require => 'active_support'
gem 'yajl-ruby', :require => [ 'yajl', 'yajl/json_gem' ]
gem 'faraday'

gem "sentry-raven", :git => "https://github.com/getsentry/raven-ruby.git"

# service: mail
gem 'mail', '~> 2.2'

# service :campfire
gem 'tinder', '~> 1.4'

# service :hipchat
gem 'hipchat-api'

# service :libratometrics
gem 'librato-metrics', '~> 0.5'

group :development do
  gem 'foreman'
end

group :building do
  gem 'rake'
end

group :production do
  gem 'pg'

  # Use unicorn as the web server
  gem 'unicorn'
end

group :test do
  gem 'mocha', :require => false
end