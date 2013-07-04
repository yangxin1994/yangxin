require 'rubygems'
require 'spork'

Spork.prefork do
  # Loading more in this block will cause your tests to run faster. However, 
  # if you change any configuration or code from libraries loaded here, you'll
  # need to restart spork for it take effect.
  # This file is copied to spec/ when you run 'rails generate rspec:install'
  ENV["RAILS_ENV"] ||= 'test'
  require File.expand_path("../../config/environment", __FILE__)
  require 'rspec/rails'
  require 'rspec/autorun'

  # Requires supporting ruby files with custom matchers and macros, etc,
  # in spec/support/ and its subdirectories.
  Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

  RSpec.configure do |config|
    # == Mock Framework
    #
    # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
    #
    # config.mock_with :mocha
    # config.mock_with :flexmock
    # config.mock_with :rr
    config.mock_with :rspec

    # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
    # config.fixture_path = "#{::Rails.root}/spec/fixtures"

    # If you're not using ActiveRecord, or you'd prefer not to run each of your
    # examples within a transaction, remove the following line or assign false
    # instead of true.
    # config.use_transactional_fixtures = true

    # If true, the base class of anonymous controllers will be inferred
    # automatically. This will be the default behavior in future versions of
    # rspec-rails.
    config.infer_base_class_for_anonymous_controllers = false
  end
end

Spork.each_run do
  # This code will be run each time you run your specs.
  FactoryGirl.reload
end


def admin_signin
    admin = FactoryGirl.create(:admin)
    original_password = Encryption.decrypt_password(admin.password)
    post "/sessions",
      email_mobile: admin.email,
      password: original_password,
      keep_signed_in: true
    response.status.should be(200)
    auth_key = JSON.parse(response.body)["value"]["auth_key"]

    return auth_key
end

def user_signin(user)
  @signin_user = FactoryGirl.create(user)
    original_password = Encryption.decrypt_password(@signin_user.password)
    post "/sessions",
      email_mobile: @signin_user.email,
      password: original_password,
      keep_signed_in: true
    response.status.should be(200)
    auth_key = JSON.parse(response.body)["value"]["auth_key"]

    return auth_key
end

def agent_signin
  agent_task = FactoryGirl.create(:agent_task)
  original_password = Encryption.decrypt_password(agent_task.password)
  post "/agent/sessions",
    email_mobile: agent_task.email,
    password: original_password
    response.status.should be(200)
    auth_key = JSON.parse(response.body)["value"]["auth_key"]
  return auth_key
end

def clear(model_name)
  Object::const_get(model_name).destroy_all
end