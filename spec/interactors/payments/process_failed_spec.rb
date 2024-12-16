# frozen_string_literal: true

RSpec.shared_examples 'fails payment' do
  it 'fails payment' do
    expect { context }.to change {
      updated_payment = DB.relations['payments'].by_pk(payment[:id]).one
      [updated_payment[:paid_at], updated_payment[:status]]
    }.from([nil, 'pending']).to([Time.now, 'failed'])
  end
end

describe Payments::ProcessFailed do
  subject(:context) { described_class.call(payment_id: payment[:id], payment: payment) }

  describe '.call' do
    around { |ex| Timecop.freeze(Date.today) { ex.run } }

    context "when subscription has 'pending' status" do
      let(:subscription) { Factory[:subscription, :pending] }
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

      it_behaves_like 'fails payment'

      it 'fails subscription' do
        expect { context }.to change {
          DB.relations['subscriptions'].by_pk(subscription[:id]).one[:status]
        }.from('pending').to('failed')
      end

      it 'fails renewal_invoice' do
        expect { context }.to change {
          DB.relations['renewal_invoices'].by_pk(renewal_invoice[:id]).one[:status]
        }.from('pending').to('failed')
      end
    end

    context "when subscription has 'partially_paid' status" do
      let(:subscription) { Factory[:subscription, :partially_paid] }
      let(:renewal_invoice) do
        Factory[
          :renewal_invoice,
          subscription_id: subscription[:id],
          amount_cents: subscription[:amount_cents],
          amount_cents_left: subscription[:amount_cents],
          invoiced_at: subscription[:next_renewal_at],
          status: 'partially_paid'
        ]
      end
      let(:payment) do
        payment = Factory[
          :payment,
          renewal_invoice_id: renewal_invoice[:id],
          amount_cents: renewal_invoice[:amount_cents],
          is_partial: true,
          status: 'pending'
        ]
        DB.relations['payments'].combine(:renewal_invoice).by_pk(payment[:id]).one
      end

      it_behaves_like 'fails payment'

      it 'does not change subscription' do
        expect { context }.not_to(change { DB.relations['subscriptions'].by_pk(subscription[:id]).one })
      end

      it 'does not change renewal_invoice' do
        expect { context }.not_to(change { DB.relations['renewal_invoices'].by_pk(renewal_invoice[:id]).one })
      end
    end
  end
end
