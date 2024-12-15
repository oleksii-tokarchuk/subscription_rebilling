# frozen_string_literal: true

formatter = proc do |severity, time, _progname, msg|
  msg = { message: msg } if msg.is_a?(String)
  [{ severity: severity, time: time.strftime('%Y-%m-%d %H:%M:%S.%L'), **msg }.to_json, "\n"].join
end
LOGGER = Logger.new(File.join(__dir__, "../../log/#{ENV.fetch('APP_ENV')}.log"), formatter: formatter)
