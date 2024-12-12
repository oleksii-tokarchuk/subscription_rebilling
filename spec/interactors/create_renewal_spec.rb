# frozen_string_literal: true

describe CreateRenewal do
  subject(:context) { described_class.call(subscription_id: subscription[:id]) }

  let!(:subscription) { Factory[:subscription, :for_renewal] }

  describe '.call' do
    it 'creates renewal invoice' do
      expect { context }.to change(DB.relations['renewal_invoices'], :count).from(0).to(1)
      expect(DB.relations['renewal_invoices'].first).to match(
        id: an_instance_of(Integer),
        subscription_id: subscription[:id],
        amount_cents: subscription[:amount_cents],
        amount_cents_left: subscription[:amount_cents],
        invoiced_at: subscription[:next_renewal_at],
        status: 'pending'
      )
    end

    it 'creates payment' do
      expect { context }.to change(DB.relations['payments'], :count).from(0).to(1)

      renewal_invoice = DB.relations['renewal_invoices'].first
      expect(DB.relations['payments'].first).to match(
        id: an_instance_of(Integer),
        renewal_invoice_id: renewal_invoice[:id],
        amount_cents: renewal_invoice[:amount_cents],
        status: 'pending',
        is_partial: false,
        paid_at: nil
      )
    end

    it 'updates subscription status' do
      expect { context }
        .to change { DB.relations['subscriptions'].fetch(subscription[:id])[:status] }.from('paid').to('pending')
    end

    it 'schedules ProcessRenewalPaymentJob for renewal invoice payment' do
      expect { context }.to change(ProcessRenewalPaymentJob.jobs, :size).from(0).to(1)
      expect(ProcessRenewalPaymentJob).to have_enqueued_sidekiq_job(DB.relations['payments'].first[:id])
    end
  end
end
