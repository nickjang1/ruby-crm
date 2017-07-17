source 'http://rubygems.org'
ruby '2.0.0'

gem 'actionview-encoded_mail_to'
gem 'rails', '4.0.5'
gem 'pg', '~> 0.16.0'
gem 'foreman', '~> 0.63.0'
gem 'airbrake'

gem 'settingslogic'

# Server
gem 'unicorn' #staging and production
gem 'thin', '~> 1.5.1', group: :development

gem 'haml-rails', '~> 0.5.3'
gem 'slim'
gem 'simple_form', '~> 3.0.0'
gem 'select2-rails', '~> 3.4.2'
gem 'devise', '~> 3.2.4'
gem 'ranked-model', '~> 0.4'
gem "polyamorous", :git => "git://github.com/activerecord-hackery/polyamorous.git"
gem 'squeel', git: 'https://github.com/activerecord-hackery/squeel.git'
gem 'ransack'
gem 'kaminari', '~> 0.14.1'
gem 'kaminari-bootstrap', '~> 0.1.3'
gem 'paranoia', '~> 2.0'
gem 'paperclip', '~> 3.5.0'
gem 'closure_tree', '~> 4.2.4'
gem 'state_machine', '~> 1.2.0'
gem 'wicked_pdf'
gem 'cancan', '~> 1.6.10'
gem 'phaxio', '~> 0.4.0'
gem 'roo', '~> 1.11.2'
gem 'rubyzip', '< 1.0.0' #Higher breaks roo
gem 'delorean', '~> 2.1.0'
gem 'breadcrumbs_on_rails'
gem 'carrierwave'
gem 'mini_magick'
gem 'pg_search'

# Simpler currency conversions and display helpers
# for currency objects
gem 'money-rails'

gem 'bourbon', '~> 3.1.8'
gem 'sass-rails', '4.0.2'
gem 'therubyracer'
gem 'less-rails'

gem 'coffee-rails', '>= 4.0.0'

gem 'uglifier', '>= 1.3.0'

# No longer used, but necessary to run the migrations that
# set it up and remove it
gem 'queue_classic', require: false
gem 'font-awesome-sass-rails', '~> 3.0.2.2'

gem 'turbolinks', '~> 1.3.0'
#gem 'jquery-turbolinks'
gem 'js-routes', '~> 0.9.0'
gem 'jquery-rails', '~> 3.0.1'
#gem 'jquery-ui-rails', '~> 4.0.3'
gem 'draper'
gem 'mail_view', "~> 2.0.4"
gem 'request_store'
gem 'sidekiq'
gem 'sinatra', require: false
gem 'pusher'
gem 'rabl'
gem 'oj'
gem 'builder'
gem 'rest-client'
gem 'xml-simple', require: 'xmlsimple'
gem 'groupdate'
gem 'pundit'
gem 'paper_trail'
gem 'twilio-ruby', '~> 4.2.1'
gem 'public_activity'
gem 'sentient_user'
gem 'puma'
gem 'acts_as_commentable_with_threading'
gem 'acts_as_votable'
gem 'symmetric-encryption'
gem 'blazer'
# https://github.com/rails/rails/issues/8005
gem 'activerecord_lax_includes', path: 'vendor/patch/active-record-lax-includes'

group :test do
  gem 'simplecov', '~> 0.9.0'#, require: false
  gem 'guard-minitest', '~> 0.5.0'
  gem 'minitest-rails', '~> 0.9.2'
  gem 'minitest-rails-capybara', '~> 0.9.0'
  gem 'capybara_minitest_spec', '~> 1.0.0'
  gem 'rb-fsevent', '~> 0.9.3'
  gem 'minitest-metadata', '~> 0.4.0'
  gem 'minitest-reporters'
  gem 'database_cleaner', '~> 1.3.0'
  # gem 'capybara-webkit', '~> 1.0.0'
  gem 'poltergeist'#, '~> 1.5.0'
  gem 'timecop'
  gem 'm'
  gem 'selenium-webdriver'
  gem 'capybara-screenshot'
end

group :development do
  gem 'coffee-rails-source-maps'

  gem 'better_errors', '~> 0.9.0'
  gem 'binding_of_caller', '~> 0.7.1'
  gem 'meta_request', '~> 0.2.6'
  gem 'rails-erd', '~> 1.1.0'
  #gem 'guard-livereload', '~> 1.4.0'
  gem 'quiet_assets', '~> 1.0.2'
  gem 'letter_opener_web'
  gem 'bullet'
  gem 'capistrano', '~> 3.1'
  gem 'capistrano-rvm',     require: false
  gem 'capistrano-rails',   require: false
  gem 'capistrano-bundler', require: false
  gem 'capistrano3-puma',   require: false
  gem 'capistrano-sidekiq', require: false
  gem 'airbrussh', require: false
end

# group :development, :test do
  gem 'wkhtmltopdf-binary', '~> 0.9.9.1'
  gem 'factory_girl_rails', '~> 4.2.1'
  gem 'faker', '~> 1.1.2'
# end
  #
group :test, :development do
  gem 'jasmine-rails'
  gem 'jazz_hands'
  gem 'pry', '~> 0.9.12.2'
  gem 'pry-rails', '~> 0.3.1'
  # gem 'pry-debugger', '~> 0.2.2'
  gem 'pry-byebug'
  gem 'pry-stack_explorer', '~> 0.4.9'
  gem 'sinon-rails'
  gem "parallel_tests"
end
