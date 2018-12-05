# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'
require 'spec_helper'
require 'ffaker'
require 'devise'
require 'simplecov'
require 'database_cleaner'
require 'factory_bot_rails'
require 'selenium/webdriver'
require 'support/database_cleaner'
require 'webmock/rspec'


# Add additional requires below this line. Rails is not loaded until this point!

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
# Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

# Checks for pending migration and applies them before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!
SimpleCov.start

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  # config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.

  config.use_transactional_fixtures = false
  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")
  
  # make url helpers accessible
  config.include Rails.application.routes.url_helpers
  config.before(:each) do
    default_url_options[:locale] = I18n.default_locale
  end

  # Timecop.freeze breaks Capybara features if not returned
  config.before(:each) do
    Timecop.return
  end

  # Devise controller helpers
  config.include Devise::Test::ControllerHelpers, type: :controller
end
  

# shoulda matchers
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

# Capybara
Capybara.register_driver :chrome do |app|
  Capybara::Selenium::Driver.new(app, browser: :chrome)
end
Capybara.register_driver :headless_chrome do |app|
  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
    chromeOptions: { args: %w(headless disable-gpu) }
  )
  Capybara::Selenium::Driver.new app,
    browser: :chrome,
    desired_capabilities: capabilities
end
# in order to see capybara tests in browser:
# Capybara.javascript_driver = :chrome
# else:
Capybara.javascript_driver = :headless_chrome
Capybara.server_port = '3001'
Capybara.server = :puma, { Silent: true }

# Webmock (reject any outside API calls)
WebMock.disable_net_connect!(allow_localhost: true)

RSpec.configure do |config|
  config.before(:each) do
    # mturk
    stub_request(:any, /mturk-requester(?:-sandbox)?.us-east-1.amazonaws.com/)
    # any valid tweet id
    stub_request(:get, /api.twitter.com\/1.1\/statuses\/show\/[1-9]\d*.json/)
      .to_return(status: 200, body: {id: '20'}.to_json, :headers => {"Content-Type"=> "application/json"})
    # invalid tweet id 0
    stub_request(:get, /api.twitter.com\/1.1\/statuses\/show\/0.json/)
      .to_return(status: 400, body: {id: '0'}.to_json, :headers => {"Content-Type"=> "application/json"})
  end
end

