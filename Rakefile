# frozen_string_literal: true

require 'rom/sql/rake_task'

namespace :db do
  desc 'Setup ROM container for db tasks'
  task :setup do
    require 'rom-sql'

    ENV['APP_ENV'] ||= 'development'
    ROM::SQL::RakeSupport.env = ROM::Configuration.new(:sql, "sqlite://db/#{ENV.fetch('APP_ENV', nil)}.db")
  end

  desc 'Load the seed data from db/seeds.rb'
  task :seed do
    seed_file = File.join(__dir__, 'db/seeds.rb')
    load(seed_file) if File.exist?(seed_file)
  end
end

desc 'Schedule renewals for subscriptions due today or earlier'
task :schedule_renewals do
  require_relative 'config/application'

  ScheduleRenewals.call
end
