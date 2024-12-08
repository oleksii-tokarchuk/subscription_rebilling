# frozen_string_literal: true

require 'bundler/setup'

ENV['APP_ENV'] ||= 'development'

Bundler.require(:default, ENV.fetch('APP_ENV', nil))

Dir[File.join(__dir__, '../app/**/*.rb')].each { require _1 }

rom_config = ROM::Configuration.new(:sql, "sqlite://db/#{ENV.fetch('APP_ENV', nil)}.db") do |config|
  config.register_relation(Persistence::Relations::Subscriptions)
end

if rom_config.gateways[:default].pending_migrations?
  raise "There are pending migrations. Run 'APP_ENV=#{ENV.fetch('APP_ENV', nil)} rake db:migrate' to apply them."
end

DB = ROM.container(rom_config)
