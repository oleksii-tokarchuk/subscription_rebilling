# frozen_string_literal: true

require_relative '../config/application'

create_subscriptions = DB.relations['subscriptions'].command(:create, result: :many)
subscriptions = Array.new(20) do
  {
    amount_cents: rand(100..10_000),
    next_renewal_at: Date.today + rand(-15..-5),
    status: %w[paid].sample
  }
end
create_subscriptions.call(subscriptions)
