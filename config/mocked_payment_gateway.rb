# frozen_string_literal: true

require 'webrick'
require 'json'

server = WEBrick::HTTPServer.new(Port: 3333, BindAddress: '0.0.0.0')

server.mount_proc '/paymentIntents/create' do |req, res|
  if req.request_method == 'POST'
    res['Content-Type'] = 'application/json'
    res.body = { status: %w[success failed insufficient_funds].sample }.to_json
  end
end

server.start
