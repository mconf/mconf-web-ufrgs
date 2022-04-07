# This file is part of Mconf-Web, a web application that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2015 Mconf.
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

# This file is copied to spec/ when you run 'rails generate rspec:install'

require 'codeclimate-test-reporter'
CodeClimate::TestReporter.start

require 'simplecov'
SimpleCov.start if ENV["COVERAGE"]

ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'shoulda/matchers'
require 'cancan/matchers'

# Load public activity to disabled it and reduce load
# Disabled in all tests and enabled for all features
require 'public_activity/testing'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

ActionMailer::Base.delivery_method = :test
ActionMailer::Base.perform_deliveries = true
ActionMailer::Base.deliveries = []
ActionMailer::Base.default_url_options = { :host => 'localhost:3001' }

Geocoder.configure(:lookup => :test)

Geocoder::Lookup::Test.set_default_stub(
  [
    {
      'latitude'     => 40.7143528,
      'longitude'    => -74.0059731,
      'address'      => 'New York, NY, USA',
      'state'        => 'New York',
      'state_code'   => 'NY',
      'country'      => 'United States',
      'country_code' => 'US'
    }
  ]
)

BCrypt::Engine.cost = 4

# Disable all external HTTP requests by default
# Allow requests to codeclimate for reporinting code coverage
require 'webmock/rspec'
WebMock.disable_net_connect!(allow_localhost: true, allow: 'codeclimate.com')

# Temporary workaround for https://github.com/thoughtbot/shoulda-matchers/issues/809#issuecomment-165383383
Shoulda::Matchers::ActionController::RouteParams::PARAMS_TO_SYMBOLIZE = []

RSpec.configure do |config|
  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec

  Zonebie.set_random_timezone

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  # config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.

  # TODO: set to false only to send emails with devise-async and capybara
  # see http://stackoverflow.com/questions/16732060/devise-async-sidekiq-rspec-integration-spec-fails
  # use databasecleaner or disable this only in the specific features that need it
  config.use_transactional_fixtures = false

  # Make the rails routes avaiable in all specs
  #config.include Rails.application.routes.url_helpers

  # we don't ever run migration specs, they should be used individually
  config.filter_run_excluding :migration => true
  config.run_all_when_everything_filtered = true

  # To use old default of rspec 2
  config.infer_spec_type_from_file_location!

  config.include Devise::TestHelpers, :type => :controller
  config.include ControllerMacros, :type => :controller
  config.extend Helpers::ClassMethods
  config.include FeatureHelpers, :type => :feature

  config.before(:suite) do
    # setup the current site for the first time and update some things that need configurations
    # from the site table
    Helpers.setup_site
    # this is done in an initializer, so have to do it again to prevent first run errors
    Devise.mailer_sender = Site.current.smtp_sender
  end

  config.before(:each) do |example|
    ResqueSpec.reset!
    ActionMailer::Base.deliveries.clear
    Helpers.setup_site
    Helpers.set_custom_ability_actions([])
    Capybara.current_driver = :webkit if example.metadata[:with_js]

    # To correctly test cases where referer and hostname are used
    Capybara.app_host = "http://#{Site.current.domain}"

    PublicActivity.enabled = false
    # To enable in a block of tests, use:
    #   PublicActivity.with_tracking do
    #     # your test code goes here
    #   end
  end

  config.before(:each, type: :worker) do |example|
    # most of the workers rely on recent activities
    PublicActivity.enabled = true
  end

  # We want features as close to the production environment as possible, so render error
  # pages instead of raising exceptions.
  config.before(:each, type: :feature) do |example|
    Rails.application.config.consider_all_requests_local = false
    PublicActivity.enabled = true
  end

  config.around(:each) do |example|
    # use :transaction for all, unless explicitly defined that it needs :truncation
    # :js tests (capybara-webkit) also will only work with :truncation
    use_truncation = example.metadata[:with_truncation] || example.metadata[:with_js]

    if use_truncation
      DatabaseCleaner.strategy = :truncation
    else
      DatabaseCleaner.strategy = :transaction
    end

    DatabaseCleaner.start
    example.run
    DatabaseCleaner.clean

    Helpers.reload_seeds if use_truncation

    Capybara.reset_sessions!
  end

  config.after(:each) do
    Capybara.use_default_driver
    if Rails.env.test?
      FileUtils.rm_rf(Dir["#{Rails.root}/spec/support/uploads"])
    end
  end
end

# Note: this was being included directly in the factories that need `fixture_file_upload`, but
# was causing errors in some other tests, so now it's done here. See more at:
# stackoverflow.com/questions/13673639/accessing-session-from-a-helper-spec-in-rspec#answer-13697474
FactoryGirl::SyntaxRunner.class_eval do
  include ActionDispatch::TestProcess
end
