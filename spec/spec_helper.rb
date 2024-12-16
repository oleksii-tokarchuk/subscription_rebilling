# frozen_string_literal: true

ENV['APP_ENV'] ||= 'test'

require_relative '../config/application'
require 'sidekiq/testing'

RSpec.configure do |config|
  config.order = :random

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  DatabaseCleaner[:sequel].strategy = :transaction

  config.before do
    DatabaseCleaner[:sequel].start
  end

  config.after do
    DatabaseCleaner[:sequel].clean
  end
end

Timecop.safe_mode = true

RSpec::Sidekiq.configure do |config|
  config.warn_when_jobs_not_processed_by_sidekiq = false
end

Factory = ROM::Factory.configure do |config|
  config.rom = DB
end

Dir[File.join(File.dirname(__FILE__), '/factories/*.rb')].each { require _1 }
