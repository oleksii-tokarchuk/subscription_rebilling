# frozen_string_literal: true

RSpec.shared_examples 'updates payment' do
  it 'updates payment' do
    expect { context }.to change {
      updated_payment = DB.relations['payments'].by_pk(payment[:id]).one
      [updated_payment[:paid_at], updated_payment[:status]]
    }.from([nil, 'pending']).to([Time.now, 'insufficient_funds'])
  end
end

RSpec.shared_examples 'creates partial payment' do |rate, amount|
  it "creates partial payment with #{rate} amount" do
    expect { context }.to change(DB.relations['payments'], :count).by(1)

    expect(DB.relations['payments'].last).to have_attributes(
      id: an_instance_of(Integer),
      renewal_invoice_id: renewal_invoice[:id],
      amount_cents: amount,
      status: 'pending',
      is_partial: true,
      paid_at: nil
    )
  end
end

describe Payments::ProcessInsufficientFunds do
  subject(:context) { described_class.call(payment_id: payment[:id], payment: payment) }

  describe '.call' do
    around { |ex| Timecop.freeze(Date.today) { ex.run } }

    context 'when retries with reduced amount left' do
      let(:subscription) { Factory[:subscription, :pending] }
      let(:renewal_invoice) do
        Factory[
          :renewal_invoice,
          subscription_id: subscription[:id],
          amount_cents: 1000,
          amount_cents_left: 1000,
          invoiced_at: subscription[:next_renewal_at],
          status: 'pending'
        ]
      end
      # rubocop:disable RSpec/LetSetup
      let!(:payment) do
        payment = Factory[
          :payment,
          renewal_invoice_id: renewal_invoice[:id],
          amount_cents: renewal_invoice[:amount_cents],
          status: 'pending'
        ]
        DB.relations['payments'].combine(:renewal_invoice).by_pk(payment[:id]).one
      end
      # rubocop:enable RSpec/LetSetup

      it_behaves_like 'updates payment'
      it_behaves_like 'creates partial payment', '75%', 750

      it 'schedules ProcessRenewalPaymentJob for partial payment' do
        expect { context }.to change(ProcessRenewalPaymentJob.jobs, :size).from(0).to(1)
        expect(ProcessRenewalPaymentJob).to have_enqueued_sidekiq_job(DB.relations['payments'].last[:id]).in(60)
      end

      it 'does not change subscription' do
        expect { context }.not_to(change { DB.relations['subscriptions'].by_pk(subscription[:id]).one })
      end

      it 'does not change renewal_invoice' do
        expect { context }.not_to(change { DB.relations['renewal_invoices'].by_pk(renewal_invoice[:id]).one })
      end

      context 'when payment is partial' do
        let(:payment) do
          payment = Factory[
            :payment,
            renewal_invoice_id: renewal_invoice[:id],
            amount_cents: renewal_invoice[:amount_cents] - 1,
            is_partial: true,
            status: 'pending'
          ]
          DB.relations['payments'].combine(:renewal_invoice).by_pk(payment[:id]).one
        end

        it_behaves_like 'creates partial payment', '50%', 500

        context 'when payment is 2nd partial' do
          before do
            Factory[
              :payment,
              renewal_invoice_id: renewal_invoice[:id],
              amount_cents: renewal_invoice[:amount_cents] - 1,
              is_partial: true,
              status: 'insufficient_funds'
            ]
          end

          it_behaves_like 'creates partial payment', '25%', 250
        end
      end
    end

    context 'when retries with reduced amount are exhausted' do
      before do
        3.times do
          Factory[
            :payment,
            renewal_invoice_id: renewal_invoice[:id],
            amount_cents: renewal_invoice[:amount_cents] - 1,
            is_partial: true,
            status: 'insufficient_funds'
          ]
        end
      end

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
        # rubocop:disable RSpec/LetSetup
        let!(:payment) do
          payment = Factory[
            :payment,
            renewal_invoice_id: renewal_invoice[:id],
            amount_cents: renewal_invoice[:amount_cents] - 1,
            is_partial: true,
            status: 'pending'
          ]
          DB.relations['payments'].combine(:renewal_invoice).by_pk(payment[:id]).one
        end
        # rubocop:enable RSpec/LetSetup

        it_behaves_like 'updates payment'

        it 'does not create partial payment' do
          expect { context }.not_to(change(DB.relations['payments'], :count))
        end

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
        # rubocop:disable RSpec/LetSetup
        let!(:payment) do
          payment = Factory[
            :payment,
            renewal_invoice_id: renewal_invoice[:id],
            amount_cents: renewal_invoice[:amount_cents],
            is_partial: true,
            status: 'pending'
          ]
          DB.relations['payments'].combine(:renewal_invoice).by_pk(payment[:id]).one
        end
        # rubocop:enable RSpec/LetSetup

        it_behaves_like 'updates payment'

        it 'does not create partial payment' do
          expect { context }.not_to(change(DB.relations['payments'], :count))
        end

        it 'does not change subscription' do
          expect { context }.not_to(change { DB.relations['subscriptions'].by_pk(subscription[:id]).one })
        end

        it 'does not change renewal_invoice' do
          expect { context }.not_to(change { DB.relations['renewal_invoices'].by_pk(renewal_invoice[:id]).one })
        end
      end
    end
  end
end
