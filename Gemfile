require 'rbconfig'
HOST_OS = RbConfig::CONFIG['host_os']
source 'http://rubygems.org'

gem 'rails', '3.1.0'

gem 'httparty'
gem 'sidekiq'
gem "kiqstand"
gem 'whenever', :require => false
gem 'sinatra', require: false
gem 'slim'

gem 'rack-protection'
gem 'mongoid', " ~> 3.0"
gem 'bson_ext'
gem 'ezcrypto'
gem 'log4r'
gem 'memcache-client'
gem 'kaminari'
gem 'certified'

gem 'rest-client'
if HOST_OS =~ /linux/i
  gem 'therubyracer', '>= 0.8.2'
end
group :assets do
  gem 'sass-rails', "  ~> 3.1.4"
  gem 'coffee-rails', "~> 3.1.0"
  gem 'uglifier'
	gem 'haml'
	gem 'haml-rails'
	gem 'sass'
	gem 'jquery-rails'
end

gem 'mime-types'

group :test, :development, :staging do
  gem 'guard-spork'
  gem "spork-minitest"
  gem "guard-minitest"#, :git => 'https://github.com/karmaQ/guard-minitest.git'
  gem 'minitest-rails'
  gem 'rb-fsevent', '~> 0.9.1'
  gem 'turn', :require => false
	gem 'factory_girl_rails', "~> 3.0"
  gem 'pry-rails'
end

group :production do
  gem 'passenger'
end

gem 'quill_common', :path => "../quill_common"
gem 'roadie'		# html email
