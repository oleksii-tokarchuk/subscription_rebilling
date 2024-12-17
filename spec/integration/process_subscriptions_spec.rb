# frozen_string_literal: true

describe 'process subscriptions' do
  subject(:process_subscriptions) { ScheduleRenewals.call }

  around do |ex|
    Sidekiq::Testing.inline! do
      Timecop.freeze(Date.new(2024, 3, 31)) { ex.run }
    end
  end

  before do
    Factory[
      :subscription,
      amount_cents: 10_000,
      next_renewal_at: Date.new(2024, 3, 25),
      status: 'paid'
    ]
  end

  context 'when successfuly paid' do
    before do
      allow(Net::HTTP).to receive(:post)
        .and_return(instance_double(Net::HTTPOK, body: { 'status' => 'success' }.to_json))
    end

    it 'renews subscription' do
      process_subscriptions

      expect(DB.relations['subscriptions'].to_a).to contain_exactly({
        id: an_instance_of(Integer),
        amount_cents: 10_000,
        next_renewal_at: Date.new(2024, 4, 25),
        status: 'paid'
      })
    end

    it 'creates renewal invoice' do
      process_subscriptions

      expect(DB.relations['renewal_invoices'].to_a).to contain_exactly({
        id: an_instance_of(Integer),
        subscription_id: an_instance_of(Integer),
        amount_cents: 10_000,
        amount_cents_left: 0,
        invoiced_at: Date.new(2024, 3, 25),
        status: 'paid'
      })
    end

    it 'creates payment' do
      process_subscriptions

      expect(DB.relations['payments'].map_to(nil).to_a).to contain_exactly({
        id: an_instance_of(Integer),
        renewal_invoice_id: an_instance_of(Integer),
        amount_cents: 10_000,
        is_partial: false,
        paid_at: Time.now,
        status: 'paid'
      })
    end
  end

  context 'when failed' do
    before do
      allow(Net::HTTP).to receive(:post)
        .and_return(instance_double(Net::HTTPOK, body: { 'status' => 'failed' }.to_json))
    end

    it 'fails subscription' do
      process_subscriptions

      expect(DB.relations['subscriptions'].to_a).to contain_exactly({
        id: an_instance_of(Integer),
        amount_cents: 10_000,
        next_renewal_at: Date.new(2024, 3, 25),
        status: 'failed'
      })
    end

    it 'fails renewal invoice' do
      process_subscriptions

      expect(DB.relations['renewal_invoices'].to_a).to contain_exactly({
        id: an_instance_of(Integer),
        subscription_id: an_instance_of(Integer),
        amount_cents: 10_000,
        amount_cents_left: 10_000,
        invoiced_at: Date.new(2024, 3, 25),
        status: 'failed'
      })
    end

    it 'fails payment' do
      process_subscriptions

      expect(DB.relations['payments'].map_to(nil).to_a).to contain_exactly({
        id: an_instance_of(Integer),
        renewal_invoice_id: an_instance_of(Integer),
        amount_cents: 10_000,
        is_partial: false,
        paid_at: Time.now,
        status: 'failed'
      })
    end
  end

  context 'when all attempts are insufficient funds' do
    before do
      allow(Net::HTTP).to receive(:post)
        .and_return(instance_double(Net::HTTPOK, body: { 'status' => 'insufficient_funds' }.to_json))
    end

    it 'fails subscription' do
      process_subscriptions

      expect(DB.relations['subscriptions'].to_a).to contain_exactly({
        id: an_instance_of(Integer),
        amount_cents: 10_000,
        next_renewal_at: Date.new(2024, 3, 25),
        status: 'failed'
      })
    end

    it 'fails renewal invoice' do
      process_subscriptions

      expect(DB.relations['renewal_invoices'].to_a).to contain_exactly({
        id: an_instance_of(Integer),
        subscription_id: an_instance_of(Integer),
        amount_cents: 10_000,
        amount_cents_left: 10_000,
        invoiced_at: Date.new(2024, 3, 25),
        status: 'failed'
      })
    end

    it 'creates payments' do
      process_subscriptions

      expect(DB.relations['payments'].map_to(nil).to_a).to contain_exactly(
        {
          id: an_instance_of(Integer),
          renewal_invoice_id: an_instance_of(Integer),
          amount_cents: 10_000,
          is_partial: false,
          paid_at: Time.now,
          status: 'insufficient_funds'
        },
        {
          id: an_instance_of(Integer),
          renewal_invoice_id: an_instance_of(Integer),
          amount_cents: 7500,
          is_partial: true,
          paid_at: Time.now,
          status: 'insufficient_funds'
        },
        {
          id: an_instance_of(Integer),
          renewal_invoice_id: an_instance_of(Integer),
          amount_cents: 5000,
          is_partial: true,
          paid_at: Time.now,
          status: 'insufficient_funds'
        },
        {
          id: an_instance_of(Integer),
          renewal_invoice_id: an_instance_of(Integer),
          amount_cents: 2500,
          is_partial: true,
          paid_at: Time.now,
          status: 'insufficient_funds'
        }
      )
    end
  end

  context 'when 1st attempt is insufficient funds, 2nd and 3rd are success' do
    before do
      allow(Net::HTTP).to receive(:post).and_return(
        instance_double(Net::HTTPOK, body: { 'status' => 'insufficient_funds' }.to_json),
        instance_double(Net::HTTPOK, body: { 'status' => 'success' }.to_json),
        instance_double(Net::HTTPOK, body: { 'status' => 'success' }.to_json)
      )
    end

    it 'renews subscription' do
      process_subscriptions

      expect(DB.relations['subscriptions'].to_a).to contain_exactly({
        id: an_instance_of(Integer),
        amount_cents: 10_000,
        next_renewal_at: Date.new(2024, 4, 25),
        status: 'paid'
      })
    end

    it 'creates renewal invoice' do
      process_subscriptions

      expect(DB.relations['renewal_invoices'].to_a).to contain_exactly({
        id: an_instance_of(Integer),
        subscription_id: an_instance_of(Integer),
        amount_cents: 10_000,
        amount_cents_left: 0,
        invoiced_at: Date.new(2024, 3, 25),
        status: 'paid'
      })
    end

    it 'creates payments' do
      process_subscriptions

      expect(DB.relations['payments'].map_to(nil).to_a).to contain_exactly(
        {
          id: an_instance_of(Integer),
          renewal_invoice_id: an_instance_of(Integer),
          amount_cents: 10_000,
          is_partial: false,
          paid_at: Time.now,
          status: 'insufficient_funds'
        },
        {
          id: an_instance_of(Integer),
          renewal_invoice_id: an_instance_of(Integer),
          amount_cents: 7500,
          is_partial: true,
          paid_at: Time.now,
          status: 'paid'
        },
        {
          id: an_instance_of(Integer),
          renewal_invoice_id: an_instance_of(Integer),
          amount_cents: 2500,
          is_partial: true,
          paid_at: Time.now,
          status: 'paid'
        }
      )
    end
  end

  context 'when 2 attempts are insufficient funds, 3rd is success, 4th is failed' do
    before do
      allow(Net::HTTP).to receive(:post).and_return(
        instance_double(Net::HTTPOK, body: { 'status' => 'insufficient_funds' }.to_json),
        instance_double(Net::HTTPOK, body: { 'status' => 'insufficient_funds' }.to_json),
        instance_double(Net::HTTPOK, body: { 'status' => 'success' }.to_json),
        instance_double(Net::HTTPOK, body: { 'status' => 'failed' }.to_json)
      )
    end

    it 'sets subscription as partially paid' do
      process_subscriptions

      expect(DB.relations['subscriptions'].to_a).to contain_exactly({
        id: an_instance_of(Integer),
        amount_cents: 10_000,
        next_renewal_at: Date.new(2024, 3, 25),
        status: 'partially_paid'
      })
    end

    it 'creates partially paid renewal invoice' do
      process_subscriptions

      expect(DB.relations['renewal_invoices'].to_a).to contain_exactly({
        id: an_instance_of(Integer),
        subscription_id: an_instance_of(Integer),
        amount_cents: 10_000,
        amount_cents_left: 5000,
        invoiced_at: Date.new(2024, 3, 25),
        status: 'partially_paid'
      })
    end

    it 'creates payments' do
      process_subscriptions

      expect(DB.relations['payments'].map_to(nil).to_a).to contain_exactly(
        {
          id: an_instance_of(Integer),
          renewal_invoice_id: an_instance_of(Integer),
          amount_cents: 10_000,
          is_partial: false,
          paid_at: Time.now,
          status: 'insufficient_funds'
        },
        {
          id: an_instance_of(Integer),
          renewal_invoice_id: an_instance_of(Integer),
          amount_cents: 7500,
          is_partial: true,
          paid_at: Time.now,
          status: 'insufficient_funds'
        },
        {
          id: an_instance_of(Integer),
          renewal_invoice_id: an_instance_of(Integer),
          amount_cents: 5000,
          is_partial: true,
          paid_at: Time.now,
          status: 'paid'
        },
        {
          id: an_instance_of(Integer),
          renewal_invoice_id: an_instance_of(Integer),
          amount_cents: 5000,
          is_partial: true,
          paid_at: Time.now,
          status: 'failed'
        }
      )
    end
  end

  context 'when 1st attempt is insufficient funds, 2nd is success, 3rd is insufficient funds' do
    before do
      allow(Net::HTTP).to receive(:post).and_return(
        instance_double(Net::HTTPOK, body: { 'status' => 'insufficient_funds' }.to_json),
        instance_double(Net::HTTPOK, body: { 'status' => 'success' }.to_json),
        instance_double(Net::HTTPOK, body: { 'status' => 'insufficient_funds' }.to_json)
      )
    end

    it 'sets subscription as partially paid' do
      process_subscriptions

      expect(DB.relations['subscriptions'].to_a).to contain_exactly({
        id: an_instance_of(Integer),
        amount_cents: 10_000,
        next_renewal_at: Date.new(2024, 3, 25),
        status: 'partially_paid'
      })
    end

    it 'creates partially paid renewal invoice' do
      process_subscriptions

      expect(DB.relations['renewal_invoices'].to_a).to contain_exactly({
        id: an_instance_of(Integer),
        subscription_id: an_instance_of(Integer),
        amount_cents: 10_000,
        amount_cents_left: 2500,
        invoiced_at: Date.new(2024, 3, 25),
        status: 'partially_paid'
      })
    end

    it 'creates payments' do
      process_subscriptions

      expect(DB.relations['payments'].map_to(nil).to_a).to contain_exactly(
        {
          id: an_instance_of(Integer),
          renewal_invoice_id: an_instance_of(Integer),
          amount_cents: 10_000,
          is_partial: false,
          paid_at: Time.now,
          status: 'insufficient_funds'
        },
        {
          id: an_instance_of(Integer),
          renewal_invoice_id: an_instance_of(Integer),
          amount_cents: 7500,
          is_partial: true,
          paid_at: Time.now,
          status: 'paid'
        },
        {
          id: an_instance_of(Integer),
          renewal_invoice_id: an_instance_of(Integer),
          amount_cents: 2500,
          is_partial: true,
          paid_at: Time.now,
          status: 'insufficient_funds'
        }
      )
    end
  end

  context 'when 3 attempts are insufficient funds, and 4th and 5th are success' do
    before do
      allow(Net::HTTP).to receive(:post).and_return(
        instance_double(Net::HTTPOK, body: { 'status' => 'insufficient_funds' }.to_json),
        instance_double(Net::HTTPOK, body: { 'status' => 'insufficient_funds' }.to_json),
        instance_double(Net::HTTPOK, body: { 'status' => 'insufficient_funds' }.to_json),
        instance_double(Net::HTTPOK, body: { 'status' => 'success' }.to_json),
        instance_double(Net::HTTPOK, body: { 'status' => 'success' }.to_json)
      )
    end

    it 'renews subscription' do
      process_subscriptions

      expect(DB.relations['subscriptions'].to_a).to contain_exactly({
        id: an_instance_of(Integer),
        amount_cents: 10_000,
        next_renewal_at: Date.new(2024, 4, 25),
        status: 'paid'
      })
    end

    it 'creates partially paid renewal invoice' do
      process_subscriptions

      expect(DB.relations['renewal_invoices'].to_a).to contain_exactly({
        id: an_instance_of(Integer),
        subscription_id: an_instance_of(Integer),
        amount_cents: 10_000,
        amount_cents_left: 0,
        invoiced_at: Date.new(2024, 3, 25),
        status: 'paid'
      })
    end

    it 'creates payments' do
      process_subscriptions

      expect(DB.relations['payments'].map_to(nil).to_a).to contain_exactly(
        {
          id: an_instance_of(Integer),
          renewal_invoice_id: an_instance_of(Integer),
          amount_cents: 10_000,
          is_partial: false,
          paid_at: Time.now,
          status: 'insufficient_funds'
        },
        {
          id: an_instance_of(Integer),
          renewal_invoice_id: an_instance_of(Integer),
          amount_cents: 7500,
          is_partial: true,
          paid_at: Time.now,
          status: 'insufficient_funds'
        },
        {
          id: an_instance_of(Integer),
          renewal_invoice_id: an_instance_of(Integer),
          amount_cents: 5000,
          is_partial: true,
          paid_at: Time.now,
          status: 'insufficient_funds'
        },
        {
          id: an_instance_of(Integer),
          renewal_invoice_id: an_instance_of(Integer),
          amount_cents: 2500,
          is_partial: true,
          paid_at: Time.now,
          status: 'paid'
        },
        {
          id: an_instance_of(Integer),
          renewal_invoice_id: an_instance_of(Integer),
          amount_cents: 7500,
          is_partial: true,
          paid_at: Time.now,
          status: 'paid'
        }
      )
    end
  end

  context 'when 3 attempts are insufficient funds, and 4th is failed' do
    before do
      allow(Net::HTTP).to receive(:post).and_return(
        instance_double(Net::HTTPOK, body: { 'status' => 'insufficient_funds' }.to_json),
        instance_double(Net::HTTPOK, body: { 'status' => 'insufficient_funds' }.to_json),
        instance_double(Net::HTTPOK, body: { 'status' => 'insufficient_funds' }.to_json),
        instance_double(Net::HTTPOK, body: { 'status' => 'failed' }.to_json)
      )
    end

    it 'fails subscription' do
      process_subscriptions

      expect(DB.relations['subscriptions'].to_a).to contain_exactly({
        id: an_instance_of(Integer),
        amount_cents: 10_000,
        next_renewal_at: Date.new(2024, 3, 25),
        status: 'failed'
      })
    end

    it 'fails renewal invoice' do
      process_subscriptions

      expect(DB.relations['renewal_invoices'].to_a).to contain_exactly({
        id: an_instance_of(Integer),
        subscription_id: an_instance_of(Integer),
        amount_cents: 10_000,
        amount_cents_left: 10_000,
        invoiced_at: Date.new(2024, 3, 25),
        status: 'failed'
      })
    end

    it 'creates payments' do
      process_subscriptions

      expect(DB.relations['payments'].map_to(nil).to_a).to contain_exactly(
        {
          id: an_instance_of(Integer),
          renewal_invoice_id: an_instance_of(Integer),
          amount_cents: 10_000,
          is_partial: false,
          paid_at: Time.now,
          status: 'insufficient_funds'
        },
        {
          id: an_instance_of(Integer),
          renewal_invoice_id: an_instance_of(Integer),
          amount_cents: 7500,
          is_partial: true,
          paid_at: Time.now,
          status: 'insufficient_funds'
        },
        {
          id: an_instance_of(Integer),
          renewal_invoice_id: an_instance_of(Integer),
          amount_cents: 5000,
          is_partial: true,
          paid_at: Time.now,
          status: 'insufficient_funds'
        },
        {
          id: an_instance_of(Integer),
          renewal_invoice_id: an_instance_of(Integer),
          amount_cents: 2500,
          is_partial: true,
          paid_at: Time.now,
          status: 'failed'
        }
      )
    end
  end
end
