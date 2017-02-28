source 'https://rubygems.org'
ruby '2.3.1'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem 'rails', '~> 5.0.1'

# Postgresql db
gem 'pg', '~> 0.18'
# Ruby server
gem 'puma', '~> 3.0'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# ENV vars management
gem 'figaro', '~> 1.1.1'
# authentication
gem 'devise', '~> 4.2.0'
# font icons
gem 'font-awesome-rails', '~> 4.7.0.1'
# Pagination
gem 'kaminari', '~> 1.0.1'
# File upload 
gem 'paperclip', '~> 5.0.0'
# Forms 
gem 'simple_form', '3.4.0' 
# Bootstrap
gem 'bootstrap-sass', '3.3.6' 

group :development, :test do
  gem "rspec-rails"
  gem 'rspec-its'
  gem 'rspec-activemodel-mocks'
  # gem 'quiet_assets' # don't show asset pipeline log
  gem 'guard', git: "https://github.com/guard/guard.git"
  gem 'guard-rspec', git: "https://github.com/yannis/guard-rspec.git"
  gem 'guard-bundler'
  gem 'guard-sidekiq'
  gem 'guard-livereload'
  gem 'rb-fsevent'
  gem 'byebug', platform: :mri
  gem 'faker', '1.6.6'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '~> 3.0.5'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

group :test do
    gem 'capybara'
    # nice rspec factories
    gem 'factory_girl_rails'
    # leave your test db clean after you
    gem 'database_cleaner'
    # freeze/manage time in tests
    gem 'timecop'
    # extra RSpec matchers
    gem 'shoulda-matchers'
    # check test coverage
    gem 'simplecov', require: false
end

group :production do
  gem 'rails_12factor'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
