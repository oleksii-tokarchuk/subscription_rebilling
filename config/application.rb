# frozen_string_literal: true

ENV['APP_ENV'] ||= 'development'
ENV['BUNDLE_GEMFILE'] ||= File.join(__dir__, '../Gemfile')

require 'bundler/setup'
require 'net/http'

Bundler.require(:default, ENV.fetch('APP_ENV'))

Dir[File.join(__dir__, '../app/**/*.rb')].each { require _1 }
Dir[File.join(__dir__, './initializers/**/*.rb')].each { require _1 }
