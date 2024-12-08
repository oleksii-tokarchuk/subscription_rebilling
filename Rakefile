# frozen_string_literal: true

require 'rom/sql/rake_task'

desc 'Setup ROM container for db tasks'
namespace :db do
  task :setup do
    require 'rom-sql'

    ENV['APP_ENV'] ||= 'development'
    ROM::SQL::RakeSupport.env = ROM::Configuration.new(:sql, "sqlite://db/#{ENV.fetch('APP_ENV', nil)}.db")
  end
end
