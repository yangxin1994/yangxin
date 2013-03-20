OopsData::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Disable Rails's static asset server (Apache or nginx will already do this)
  config.serve_static_assets = false

  # Compress JavaScripts and CSS
  config.assets.compress = true

  # Don't fallback to assets pipeline if a precompiled asset is missed
  config.assets.compile = false

  # Generate digests for assets URLs
  config.assets.digest = true

  # Defaults to Rails.root.join("public/assets")
  # config.assets.manifest = YOUR_PATH

  # Specifies the header that your server uses for sending files
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for nginx

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # See everything in the log (default is :info)
  # config.log_level = :debug

  # Use a different logger for distributed setups
  # config.logger = SyslogLogger.new

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store, 'orange02:11211'

  # Enable serving of images, stylesheets, and JavaScripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
  # config.assets.precompile += %w( search.js )

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

	config.action_mailer.perform_deliveries = true
	config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    :authentication => "plain",
    :address        => "smtp.mailgun.com",
    :port           => 25,
    :domain         => "oopsdata.cn",
    :user_name      => "postmaster@oopsdata.cn",
    :password       => "73ve2nt6yxl9",
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

  config.mailgun_api_key = "key-9zcv6-e7j8aratn9viu3unvbn2zc92j3"

  # task web service
  config.task_web_service_uri = 'localhost:9001'
  config.service_port = '8001'

  # donet web service
  config.dotnet_web_service_uri = 'http://19.oopsdata.com'
  # config.dotnet_web_service_uri = 'http://192.168.1.116:80'

	# configuration for roadie
	config.action_mailer.default_url_options = {:host => 'res.oopsdata.com'}

	# configuration for quill and quillme
	config.quill_host = 'http://www.oopsdata.com'
	config.quillme_host = 'http://www.oopdata.cn'
end
