source :rubygems

gem 'sinatra'
gem 'faraday'
gem 'activesupport', '~> 2.3', :require => 'active_support'
gem 'yajl-ruby', :require => [ 'yajl', 'yajl/json_gem' ]
gem 'rake'

gem 'hoptoad_notifier'

# service: mail
gem 'mail', '~> 2.2'

# service :campfire
gem 'tinder', '~> 1.4'

# service: cloudwatch
gem 'right_aws', :git => 'git://github.com/rapportive-oss/right_aws.git'

group :production do
  gem 'pg'

  # Use unicorn as the web server
  gem 'unicorn'
end
