begin
  require "rubygems"
  require "bundler"
rescue LoadError
  raise "Could not load the bundler gem. Install it with `gem install bundler`."
end

if Gem::Version.new(Bundler::VERSION) <= Gem::Version.new("0.9.24")
  raise RuntimeError, "Your bundler version is too old." +
   "Run `gem install bundler` to upgrade."
end

begin
  # Set up load paths for all bundled gems
  ENV["BUNDLE_GEMFILE"] = File.expand_path("../../Gemfile", __FILE__)
  Bundler.setup
rescue Bundler::GemNotFound
  raise RuntimeError, "Bundler couldn't find some gems." +
    "Did you run `bundle install`?"
end

Bundler.require

$LOAD_PATH << File.expand_path('../../lib', __FILE__)

require 'papertrail_services'
require 'pluralize'

if File.exist?(local_env = File.expand_path('../local.env', __FILE__))
  IO.foreach(local_env) do |line|
    if line =~ /^([^=]+)=(.+)$/
      ENV[$1.strip] = $2.strip
    end
  end
end
