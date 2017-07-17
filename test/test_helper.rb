require 'simplecov'
SimpleCov.start 'rails' do
  add_filter "/tasks/"
end

ENV['RAILS_ENV'] = 'test'
require File.expand_path('../../config/environment', __FILE__)
# require support files
Dir[File.expand_path('../support/*.rb', __FILE__)].each {|file| require file }
 
require 'factory_girl'
require 'rails/test_help'
require 'sidekiq/testing'
Sidekiq::Testing.fake!
require 'minitest/rails'
require "minitest/reporters"
Minitest::Reporters.use!

require "capybara/rspec/matchers"

require 'minitest/rails/capybara'
#require 'minitest/metadata'
require 'capybara-screenshot/minitest'
require 'database_cleaner'

require 'capybara/poltergeist'


 # Capybara.register_driver :selenium do |app|
 #  Capybara::Selenium::Driver.new(app, :browser => :chrome)
 # end
 #
 # Capybara.javascript_driver = :selenium
Capybara.javascript_driver = :poltergeist

# Warning: Some ultraghetto bullshit lies below.
#
# Poltergeist's instance of the webapp runs in a different thread than
# our tests, so they're using a different connection.  Something about
# the way FactoryGirl creates records (might just even be the amount of
# time it takes for the DB to commit the records) means that the thread
# running PolterGeist's instance of the app can't see the stuff we create
# with Factorygirl.
#
# This solution utilizes a single connection for all work done on models.
# I'm hoping that ActiveRecord handles the mutex around this connection
# internally, otherwise things will get weird.
#
# Perhaps an alternative would be to wrap FactoryGirl stuff (maybe
# monkeyatch ::create) so that transactions are commited before the
# method returns.  Perhaps ensuring synchronicity there would probably
# solve this problem as well.
# class ActiveRecord::Base
#   mattr_accessor :single_connection
#   @@single_connection = retrieve_connection

#   def self.connection
#     return @@single_connection
#   end
# end

load_default_data()

DatabaseCleaner.strategy = :truncation, {except: %w[permission_attributes roles]}

def common_setup
  Property.current_id = Property.any? ? Property.first.id : create(:property).id
end

class MiniTest::Spec
  include FactoryGirl::Syntax::Methods
  before :each do
    DatabaseCleaner.clean
    common_setup
    DatabaseCleaner.start
  end

  after :each do
    DatabaseCleaner.clean
  end
end

class ActiveSupport::TestCase
  include FactoryGirl::Syntax::Methods
  before :each do
    DatabaseCleaner.clean
    common_setup
    DatabaseCleaner.start
  end

  after :each do
    DatabaseCleaner.clean
  end
end
 
class ActionDispatch::IntegrationTest
  include Rails.application.routes.url_helpers
  include Capybara::RSpecMatchers
  include Capybara::DSL
  include MiniTest::Metadata

  #Devise
  include Warden::Test::Helpers
  Warden.test_mode!
  include DeviseMacros

  include MailerMacros
  include CapybaraMacros
  include BoostrapMacros
  include MaintenanceMacros

  self.use_transactional_fixtures = false # doesn't make any effect at all

  def setup
    common_setup
  end

  before do
    DatabaseCleaner.start
    common_setup
    if metadata[:js] == true
      Capybara.current_driver = Capybara.javascript_driver
    end
  end

  after do
    DatabaseCleaner.clean
    Capybara.current_driver = Capybara.default_driver
  end
end
