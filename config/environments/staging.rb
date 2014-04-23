OopsData::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Disable Rails's static asset server (Apache or nginx will already do this)
  config.serve_static_assets = true

  # Compress JavaScripts and CSS
  config.assets.compress = true

  # Don't fallback to assets pipeline if a precompiled asset is missed
  config.assets.compile = true

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
  config.assets.precompile += %w( *-layout.js *-layout.css *-bundle.js *-bundle.css *-mobile.js *-mobile.css )

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
=begin
  config.action_mailer.smtp_settings = {
    :authentication => "plain",
    :address        => "smtp.critsend.com",
    :port           => 25,
    :domain         => "oopsdata.cn",
    :user_name      => "info@oopsdata.com",
    :password       => "cChzuCev9YBnhZ9Wr1H"
  }
=end

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
=begin
  config.survey_mailer_setting = {
    :authentication => "plain",
    :address        => "smtp.critsend.com",
    :port           => 25,
    :domain         => "oopsdata.cn",
    :user_name      => "info@oopsdata.com",
    :password       => "cChzuCev9YBnhZ9Wr1H"
  }
=end

  config.authkeys = {
    sina: '3198161770',
    renren: '194585',
    qq: '100418792',
    google: '36926710043',
    qihu360: 'c83cf3b2688f4f1c695bc9906a2dcf14',
    kaixin001: '173805652095b523553bc42aa44f8171',
    douban: '06b0041f88738b9e14100c5e995aa2da',
    baidu: 'STFYxeMfwouPVtMjseFymHGD',
    sohu: '9ab2466b42224c0c9b038e327db61b97'
  }

  config.mailgun_api_key = "key-9zcv6-e7j8aratn9viu3unvbn2zc92j3"

  # task web service
  config.service_port = '8001'

  # donet web service
  config.dotnet_web_service_uri = 'http://export.oopsdata.com'

	# configuration for quill and quillme
	config.quill_host = 'http://s.oopsdata.com'
	config.quillme_host = 'http://staging.wenjuanba.com'

	# configuration for roadie
	config.action_mailer.default_url_options = {:host => 'res.oopsdata.com'}

  config.mailgun_api_key = 'key-9zcv6-e7j8aratn9viu3unvbn2zc92j3'
  config.survey_email_domain = 'wenjuanba.net'
  config.user_email_domain = 'wenjuanba.cn'

  # ofcard uri
  config.ofcard_service_uri = "http://api2.ofpay.com/"
  config.ofcard_key_str = "OFCARD"
  config.ret_url = "http://staging.wenjuanba.com/orders/confirm"
  config.diaoyan = 'http://staging.diaoyan.me'
end
