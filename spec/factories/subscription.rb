# frozen_string_literal: true

Factory.define(:subscription) do |f|
  f.amount_cents rand(100..10_000)

  f.trait :for_renewal do |t|
    t.next_renewal_at { Date.today - rand(1..10) }
    t.status 'paid'
  end

  f.trait :paid do |t|
    t.next_renewal_at { Date.today + rand(1..10) }
    t.status 'paid'
  end

  f.trait :pending do |t|
    t.next_renewal_at { Date.today - rand(1..10) }
    t.status 'pending'
  end

  f.trait :partially_paid do |t|
    t.next_renewal_at { Date.today - rand(1..10) }
    t.status 'partially_paid'
  end

  f.trait :failed do |t|
    t.next_renewal_at { Date.today - rand(1..10) }
    t.status 'failed'
  end
end
