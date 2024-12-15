# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.3.6'

gem 'interactor', '~> 3.1'
gem 'rack-session', '~> 2.0'
gem 'rackup', '~> 2.2'
gem 'rake', '~> 13.2'
gem 'rom', '~> 5.3'
gem 'rom-sql', '~> 3.6.4'
gem 'sidekiq', '~> 7.3.6'
gem 'sqlite3', '~> 2.4'
gem 'webrick', '~> 1.9'

group :development, :test do
  gem 'pry', '~> 0.15'
end

group :development do
  gem 'rubocop', '~> 1.69', require: false
  gem 'rubocop-performance', '~> 1.23', require: false
  gem 'rubocop-rake', '~> 0.6', require: false
  gem 'rubocop-rspec', '~> 3.2', require: false
  gem 'rubocop-thread_safety', '~> 0.6', require: false
end

group :test do
  gem 'database_cleaner-sequel', '~> 2.0'
  gem 'rom-factory', '~> 0.12'
  gem 'rspec', '~> 3.13'
  gem 'rspec-sidekiq', '~> 5.0'
end
