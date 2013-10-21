#source 'http://rubygems.org'
source 'http://ruby.taobao.org'

gem 'rails', '~> 3.2.6'

gem "binding_of_caller", "~> 0.7.2", :group => :development
gem 'tilt','~> 1.3.2'
gem 'httparty', '~> 0.10.2'
gem 'sidekiq', '~> 2.8.0'
gem "kiqstand", '~> 1.0.0'
gem 'whenever', '~> 0.8.2', :require => false
gem 'sinatra', require: false
gem 'slim', '~> 1.3.6'

gem 'ezcrypto', '~> 0.7.2'
gem 'rack-protection', '~> 1.3.2'
gem 'log4r', '~> 1.1.10'
gem 'memcache-client', '~> 1.8.5'

gem 'certified', '~> 0.1.1'
gem 'bson_ext', '~> 1.8.2'
gem 'mongoid', " ~> 3.0"
gem 'mongoid_shortener', :path => "../mongoid_shortener"
gem 'kaminari', '~> 0.14.1'

gem 'rest-client', '~> 1.6.7'
gem 'mime-types', "~> 1.21"
gem 'string_utf8', "~> 0.0.1"
gem 'quill_common', :path => "../quill_common"
gem 'mobile-fu', "~> 1.1.1"
gem 'gon', "~> 4.1.1"

gem 'yab62', require: 'yab62'

# uploader

gem 'mini_magick', '~> 3.5.0'
gem 'carrierwave', '~> 0.8.0'
gem 'rack-raw-upload', '1.1.0'

# about mail

gem 'roadie', '~> 2.3.4'# html email
gem 'premailer-rails', '~> 1.4.0'
gem 'nokogiri', '~> 1.5.6'

# for captcha
gem 'easy_captcha'


group :assets do
  gem 'sass-rails', '~> 3.2.6'
  gem 'coffee-rails', '~> 3.2.2'

  gem 'uglifier', '~> 1.3.0'

  # gem for handlebars_assets.
  gem 'handlebars_assets', '~> 0.14.1'

  # gem for compass.
  gem 'compass-rails', '~> 1.0.3'
  # If user Rails 4.0, we should hack compass-rails 
  # TODO: follow https://github.com/Compass/compass-rails/pull/59 for the latest updates
  # gem 'compass-rails', github: "milgner/compass-rails", ref: "1749c06f15dc4b058427e7969810457213647fb8" 
  gem 'jquery-rails', "~> 2.2.1"
  # gem for bootstrap.
  gem "bootstrap-sass-rails", "~> 2.3.0.0"
  # gem 'anjlab-bootstrap-rails', :require => 'bootstrap-rails',
  #                             :github => 'anjlab/bootstrap-rails',
  #                             :branch => '3.0.0'
  # gem 'bootstrap-sass', '~> 2.1.0.0'
end

group :test do
  gem 'rspec-rails', '~> 2.13.2'
  gem "capybara", '~> 2.1.0'
  gem "guard-rspec", '~> 2.5.4'
  gem 'guard-spork', '~> 1.4.2'  #Must be set in test and development group so that generater can use it
  gem 'rb-fsevent', '~> 0.9.1', :require => false if RUBY_PLATFORM =~ /linux/ 
  gem 'rb-inotify', :require => false unless RUBY_PLATFORM =~ /linux/   # Dynamic file manager for linux
  gem 'turn', '~> 0.9.6', :require => false
  gem 'spork', '~> 0.9.2'
  gem 'factory_girl_rails', "~> 4.1"
end

group :development do
  gem 'thin'
  gem 'pry-rails', "~> 0.2.2"
  gem "better_errors", "~> 0.8.0"
  gem "rack-mini-profiler", "~> 0.1.30"
end

group :production do
  gem 'passenger'#, '~> 3.0.19'
end
