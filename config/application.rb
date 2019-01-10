require_relative 'boot'

require "csv"
require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "action_cable/engine"
require "sprockets/railtie"
# require "rails/test_unit/railtie"

# Logging formatting
require "./lib/logging"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)


module Crowdbreaks

  Locales = ['en', 'pt']
  LocalesTranslations = {'en': 'English', 'de': 'Deutsch', 'pt': 'Português'}

  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    
    # Avoid creating .coffee files, instead create .js files when using generators
    config.generators do |g|
      g.javascript_engine :js
    end

    # Internationalization
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}')]
    config.i18n.default_locale = :en
    config.i18n.fallbacks = [:en]
    config.i18n.available_locales = Locales

    # Dummy image path
    config.dummy_image_url = "https://dummyimage.com/300.png/09f/fff"

    # Dynamic error pages
    config.exceptions_app = self.routes

    # Logging
    config.log_formatter = Logging::LogFormatter.new

    # Job scheduling
    config.active_job.queue_adapter = :sidekiq

    # Issues with I18n load_path not available on assets:precompile 
    config.assets.initialize_on_precompile = false
  end
end
