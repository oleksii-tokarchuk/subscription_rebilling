# frozen_string_literal: true

rom_config = ROM::Configuration.new(:sql, "sqlite://db/#{ENV.fetch('APP_ENV')}.db") do |config|
  config.auto_registration(File.join(__dir__, '../../app/persistence/'))
  config.gateways[:default].use_logger(LOGGER)
end

if rom_config.gateways[:default].pending_migrations?
  raise "There are pending migrations. Run 'APP_ENV=#{ENV.fetch('APP_ENV')} rake db:migrate' to apply them."
end

DB = ROM.container(rom_config)
