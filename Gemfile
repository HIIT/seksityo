source 'https://rubygems.org'

#Ruby version
ruby '2.4.0'

# Coveralls to show off.
gem 'coveralls', require: false

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '5.0.2'

# Where-or for more convenient ActiveRecords
#gem 'where-or'

# gem to set locale based on browser preference
gem 'http_accept_language'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.1.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc
# Phonelib validates phone numbers
gem 'phonelib'
#Delayed jobs
gem 'delayed_job_active_record'
#Daemons for delayed jobs
gem 'daemons'
#Textmagic for more robust message sending
gem 'textmagic'

# Use ActiveModel has_secure_password
gem 'bcrypt', '~> 3.1.7'

# Use Unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'

  # Rspec for unit testing
  gem 'rspec-rails', '~> 3.0'

  # Capybara for integration testing
  gem  'capybara'

  #Capybara javascript driver
  gem "capybara-webkit"

  #Capybara email testing
  gem 'capybara-email'

end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'

  gem 'better_errors'

end

group :test do
  gem 'simplecov', require: false

  gem 'database_cleaner'

  gem "show_me_the_cookies"

  gem 'rails-controller-testing'
end

# Database gems
gem 'pg', '0.21'
gem 'rails_12factor'
