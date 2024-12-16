# frozen_string_literal: true

describe Payments::Successful::ProcessPartial do
  subject(:context) { described_class.call(payment_id: payment[:id], payment: payment) }

  describe '.call' do
    let(:subscription) { Factory[:subscription, :pending, next_renewal_at: Date.new(2024, 2, 27), amount_cents: 1000] }
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
    let!(:payment) do
      payment = Factory[
        :payment,
        renewal_invoice_id: renewal_invoice[:id],
        amount_cents: 300,
        is_partial: true,
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
      }.from(['pending', subscription[:amount_cents]]).to(['partially_paid', 700])
    end

    it 'updates subscription' do
      expect { context }.to change {
        DB.relations['subscriptions'].by_pk(subscription[:id]).one[:status]
      }.from('pending').to('partially_paid')
    end

    it 'creates final payment' do
      expect { context }.to change(DB.relations['payments'], :count).by(1)

      expect(DB.relations['payments'].last).to have_attributes(
        id: an_instance_of(Integer),
        renewal_invoice_id: renewal_invoice[:id],
        amount_cents: 700,
        status: 'pending',
        is_partial: true,
        paid_at: nil
      )
    end

    it 'schedules ProcessRenewalPaymentJob for final payment' do
      expect { context }.to change(ProcessRenewalPaymentJob.jobs, :size).from(0).to(1)
      expect(ProcessRenewalPaymentJob)
        .to have_enqueued_sidekiq_job(DB.relations['payments'].last[:id]).in(7 * 24 * 60 * 60) # 1 week
    end
  end
end
