# frozen_string_literal: true

describe Payments::Successful::ProcessFull do
  subject(:context) { described_class.call(payment_id: payment[:id], payment: payment) }

  describe '.call' do
    let(:subscription) { Factory[:subscription, :pending, next_renewal_at: Date.new(2024, 2, 27)] }
    let(:renewal_invoice) do
      Factory[
        :renewal_invoice,
        subscription_id: subscription[:id],
        amount_cents: subscription[:amount_cents],
        amount_cents_left: subscription[:amount_cents],
        invoiced_at: subscription[:next_renewal_at],
        status: 'pending'
      ]
    end
    let(:payment) do
      payment = Factory[
        :payment,
        renewal_invoice_id: renewal_invoice[:id],
        amount_cents: renewal_invoice[:amount_cents],
        status: 'pending'
      ]
      DB.relations['payments'].combine(:renewal_invoice).by_pk(payment[:id]).one
    end

    around { |ex| Timecop.freeze(Date.today) { ex.run } }

    it 'updates payment' do
      expect { context }.to change {
        updated_payment = DB.relations['payments'].by_pk(payment[:id]).one
        [updated_payment[:paid_at], updated_payment[:status]]
      }.from([nil, 'pending']).to([Time.now, 'paid'])
    end

    it 'updates renewal_invoice' do
      expect { context }.to change {
        DB.relations['renewal_invoices'].by_pk(renewal_invoice[:id]).one.values_at(:status, :amount_cents_left)
      }.from(['pending', subscription[:amount_cents]]).to(['paid', 0])
    end

    it 'updates subscription' do
      expect { context }.to change {
        DB.relations['subscriptions'].by_pk(subscription[:id]).one.values_at(:status, :next_renewal_at)
      }.from(['pending', subscription[:next_renewal_at]]).to(['paid', Date.new(2024, 3, 27)])
    end
  end
end
