# frozen_string_literal: true

ENV['APP_ENV'] ||= 'development'
ENV['BUNDLE_GEMFILE'] ||= File.join(__dir__, '../Gemfile')

require 'bundler/setup'

Bundler.require(:default, ENV.fetch('APP_ENV'))

Dir[File.join(__dir__, '../app/**/*.rb')].each { require _1 }

formatter = proc do |severity, time, _progname, msg|
  [{ severity: severity, time: time.strftime('%Y-%m-%d %H:%M:%S.%L'), **msg }.to_json, "\n"].join
end
LOGGER = Logger.new(File.join(__dir__, "../log/#{ENV.fetch('APP_ENV')}.log"), formatter: formatter)

rom_config = ROM::Configuration.new(:sql, "sqlite://db/#{ENV.fetch('APP_ENV')}.db") do |config|
  config.auto_registration(File.join(__dir__, '../app/persistence/'))
  config.gateways[:default].use_logger(Logger.new($stdout)) if ENV.fetch('APP_ENV') == 'development'
end

if rom_config.gateways[:default].pending_migrations?
  raise "There are pending migrations. Run 'APP_ENV=#{ENV.fetch('APP_ENV')} rake db:migrate' to apply them."
end

DB = ROM.container(rom_config)
