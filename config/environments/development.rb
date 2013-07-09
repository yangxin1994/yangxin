OopsData::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false
  config.server_static_assets = true
  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = true

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Do not compress assets
  config.assets.compress = false

  # Expands the lines which load the assets
  config.assets.debug = true

	#config.cache_store = :mem_cache_store, 'localhost:11211'

	config.action_mailer.perform_deliveries = true
	config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    :authentication => "plain",
    :address        => "smtp.mailgun.com",
    :port           => 25,
    :domain         => "oopsdata.net",
    :user_name      => "postmaster@oopsdata.net",
    :password       => "0nlnhy08vbk1",
    :enable_starttls_auto => true,
    :openssl_verify_mode  => 'none'
  }

  config.survey_mailer_setting = {
    :authentication => "plain",
    :address        => "smtp.mailgun.com",
    :port           => 25,
    :domain         => "oopsdata.net",
    :user_name      => "postmaster@oopsdata.net",
    :password       => "0nlnhy08vbk1",
    :enable_starttls_auto => true,
    :openssl_verify_mode  => 'none'
  }  

  # task web service
  config.service_port = '8000'
  # donet web service
  # config.dotnet_web_service_uri = 'http://192.168.1.119:80'
  config.dotnet_web_service_uri = 'http://export.oopsdata.com'

	# configuration for roadie
	config.action_mailer.default_url_options = {:host => 'quill.oopsdata.net', :port => '3000'}

	# configuration for quill and quillme
	config.quill_host = 'http://quill.oopsdata.net:3000'
	config.quillme_host = 'http://quillme.oopsdata.net:3000'

  config.mailgun_api_key = 'key-9zcv6-e7j8aratn9viu3unvbn2zc92j3'
  config.survey_email_domain = 'oopsdata.net'
  config.user_email_domain = 'oopsdata.cn'

  # ofcard uri
  config.ofcard_service_uri = "http://api2.ofpay.com/"
  config.ofcard_key_str = "OFCARD"
  config.ret_url = "http://221.221.17.98:4000/orders/confirm"
end
