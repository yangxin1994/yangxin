require 'rbconfig'
HOST_OS = RbConfig::CONFIG['host_os']
source 'http://rubygems.org'

gem 'rails', '3.1.0'

gem 'httparty'
gem 'sidekiq'
gem "kiqstand"

# Bundle edge Rails instead:
# gem 'rails',     :git => 'git://github.com/rails/rails.git'

gem 'rack-protection'
gem 'mongoid', " ~> 3.0"
gem 'bson_ext'
gem 'ezcrypto'
gem 'log4r'
gem 'memcache-client'
gem 'kaminari'
# gem 'jbuilder'
gem 'resque'
gem 'resque-status'
gem 'resque-scheduler'
gem 'oops-mail', '0.0.2', :path => "vendor/gems/oops-mail-0.0.2"
gem 'faker'
gem 'certified'

gem 'pry-rails'

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
	#gem 'mini_captcha', :path => "~/Rrojects/mini_captcha/"
	# attachment
	# gem 'carrierwave-mongoid', :require => 'carrierwave/mongoid'
  # gem for compass.
  # gem 'compass-rails'
end



gem 'mime-types'
# gem 'mini_magick', :git => 'https://github.com/karmaQ/mini_magick.git'
# Use unicorn as the web server
# gem 'unicorn'
# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'ruby-debug19', :require => 'ruby-debug'
group :test, :development do
  gem 'guard-spork'
  gem "spork-minitest"
  gem "guard-minitest"#, :git => 'https://github.com/karmaQ/guard-minitest.git'
  gem 'minitest-rails'
  gem 'rb-fsevent', '~> 0.9.1'
  gem 'turn', :require => false
	gem 'factory_girl_rails', "~> 3.0"
end

group :production do
  gem 'passenger'
end

gem 'quill_common', :path => "../quill_common"
gem 'roadie'		# html email
