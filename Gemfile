require 'rbconfig'
HOST_OS = RbConfig::CONFIG['host_os']
source 'http://rubygems.org'

gem 'rails', '3.1.0'

# Bundle edge Rails instead:
# gem 'rails',     :git => 'git://github.com/rails/rails.git'


gem 'mongoid', " ~> 2.4"
gem 'bson_ext'
gem 'ezcrypto'
gem 'log4r'
gem 'memcache-client'
gem 'kaminari'
gem 'resque'
gem 'resque-scheduler'
gem 'oops-mail', '0.0.2', :path => "vendor/gems/oops-mail-0.0.2"
gem 'faker'

gem 'haml'
gem 'haml-rails'

gem 'pry-rails'

gem 'passenger'

gem 'rest-client'
if HOST_OS =~ /linux/i
  gem 'therubyracer', '>= 0.8.2'
end
group :assets do
  gem 'sass-rails', "  ~> 3.1.4"
  gem 'coffee-rails', "~> 3.1.0"
  gem 'uglifier'
end

gem 'jquery-rails'
#gem 'mini_captcha', :path => "~/Rrojects/mini_captcha/"
# attachment
gem 'carrierwave-mongoid', :require => 'carrierwave/mongoid'
gem 'mime-types'
gem 'mini_magick', :git => 'https://github.com/karmaQ/mini_magick.git'
# Use unicorn as the web server
# gem 'unicorn'
# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'ruby-debug19', :require => 'ruby-debug'
group :test do
  # Pretty printed test output
  gem 'turn', :require => false
	gem 'minitest'
	gem 'factory_girl_rails', "~> 3.0"
end
