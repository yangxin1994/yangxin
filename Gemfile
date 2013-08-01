require 'rbconfig'
HOST_OS = RbConfig::CONFIG['host_os']
#source 'http://rubygems.org'
source 'http://ruby.taobao.org'

gem 'rails', '3.1.0'
gem 'tilt','~> 1.3.2'
gem 'httparty', '~> 0.10.2'
gem 'sidekiq', '~> 2.8.0'
gem "kiqstand", '~> 1.0.0'
gem 'whenever', '~> 0.8.2', :require => false
gem 'sinatra', require: false
gem 'slim', '~> 1.3.6'

gem 'rack-protection', '~> 1.3.2'
gem 'mongoid', " ~> 3.0"
gem 'bson_ext', '~> 1.8.2'
gem 'ezcrypto', '~> 0.7.2'
gem 'log4r', '~> 1.1.10'
gem 'memcache-client', '~> 1.8.5'
gem 'kaminari', '~> 0.14.1'
gem 'certified', '~> 0.1.1'

gem 'rest-client', '~> 1.6.7'

=begin
if HOST_OS =~ /linux/i
  gem 'therubyracer', '>= 0.8.2'
end
=end


group :assets do
  gem 'sass-rails', "  ~> 3.1.4"
  gem 'coffee-rails', "~> 3.1.0"
  gem 'uglifier', "~> 1.3.0"
  gem 'haml', "~> 4.0.0"
  gem 'haml-rails', "~> 0.4"
  gem 'sass', "~> 3.2.6"
  gem 'jquery-rails', "~> 2.2.1"
end

gem 'mime-types', "~> 1.21"

group :test, :development, :staging do
  gem 'rspec-rails', '~> 2.13.2'
  gem 'guard-spork', '~> 1.4.2'  #Must be set in test and development group so that generater can use it
  #add Rspec to instead minitest
  # gem "spork-minitest"  
  # gem "guard-minitest"#, :git => 'https://github.com/karmaQ/guard-minitest.git'
  # gem 'minitest-rails'
  gem 'rb-fsevent', '~> 0.9.1', :require => false if RUBY_PLATFORM =~ /linux/ 
  gem 'turn', '~> 0.9.6', :require => false
  gem 'factory_girl_rails', "~> 4.1"
  gem 'pry-rails', "~> 0.2.2"
  gem 'unicorn', "~> 4.6.2"
end

group :test do
  gem "capybara", '~> 2.1.0'
  gem "guard-rspec", '~> 2.5.4'
  gem 'rb-inotify', :require => false unless RUBY_PLATFORM =~ /linux/   # Dynamic file manager for linux
  gem 'guard-spork', '~> 1.4.2'    #To speed up the load time,but not Compatible well with rails 3.X
  gem 'spork', '~> 0.9.2'
end

group :production do
  gem 'passenger', '~> 3.0.19'
end

gem 'quill_common', :path => "../quill_common"
gem 'roadie', '~> 2.3.4'# html email
#gem 'premailer'		# html email
gem 'premailer-rails', '~> 1.4.0'
gem 'nokogiri', '~> 1.5.6'
