# frozen_string_literal: true

describe Persistence::Entities::Payment do
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
      amount_cents: payment_amount,
      is_partial: is_partial,
      status: 'pending'
    ]
    DB.relations['payments'].combine(:renewal_invoice).by_pk(payment[:id]).one
  end

  context 'when the payment is partial and matches the remaining amount of the renewal invoice' do
    let(:payment_amount) { renewal_invoice[:amount_cents_left] }
    let(:is_partial) { true }

    it 'returns true' do
      expect(payment).to be_final
    end
  end

  context 'when the payment is partial and do not match the remaining amount of the renewal invoice' do
    let(:payment_amount) { renewal_invoice[:amount_cents_left] - 1 }
    let(:is_partial) { true }

    it 'returns false' do
      expect(payment).not_to be_final
    end
  end

  context 'when the payment is not partial' do
    let(:payment_amount) { renewal_invoice[:amount_cents_left] }
    let(:is_partial) { false }

    it 'returns false' do
      expect(payment).not_to be_final
    end
  end
end
