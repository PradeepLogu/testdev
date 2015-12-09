TireDev::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Disable Rails's static asset server (Apache or nginx will already do this)
  config.serve_static_assets = false

  if false
    # Compress JavaScripts and CSS
    config.assets.compress = false

    # Don't fallback to assets pipeline if a precompiled asset is missed
    config.assets.compile = false
    config.assets.initialize_on_precompile = true

    # Generate digests for assets URLs
    config.assets.digest = true
  elsif true
    # Do not compress assets
    config.assets.compress = false

    # Expands the lines which load the assets
    config.assets.debug = false
  else
    config.serve_static_assets = false

    # Compress JavaScripts and CSS
    config.assets.compress = true

    # Don't fallback to assets pipeline if a precompiled asset is missed
    config.assets.compile = true

    # Generate digests for assets URLs
    config.assets.digest = true    
  end

  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.default_url_options = { :host => 'beta.treadhunter.com' }

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

  # Log the query plan for queries taking more than this (works
  # with SQLite, MySQL, and PostgreSQL)
  # config.active_record.auto_explain_threshold_in_seconds = 0.5
  config.paperclip_defaults = {
  #:storage => :s3,
  #:s3_credentials => {
  #  :bucket => ENV['AWS_BUCKET'],
  #  :access_key_id => ENV['AWS_ACCESS_KEY_ID'],
  #  :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY']
  #}  config.paperclip_defaults = {
  :storage => :s3,
  :s3_credentials => {
    :bucket => 'TirePicturesBeta',
    :access_key_id => 'AKIAJWKA65D3TYISFHBQ',
    :secret_access_key => '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'
    }
  }
  config.heroku_app = "rocky-lowlands-6041"
  config.storefront_domain = 'dogtires.com'

  config.after_initialize do
    Delayed::Job.scaler = :heroku_cedar
  end

  if false # this is intended to compress, not working right now
    config.middleware.delete(Rack::MiniProfiler)
    config.middleware.insert_after(Rack::Deflater, Rack::MiniProfiler)  
  end
end
