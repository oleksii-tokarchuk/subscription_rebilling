# frozen_string_literal: true

describe Payments::Successful::Process do
  subject(:context) { described_class.call(payment_id: payment[:id], payment: payment) }

  describe '.call' do
    let(:subscription) { Factory[:subscription, :partially_paid] }
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

    context 'when payment is final' do
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

      it 'runs Payments::Successful::ProcessFull with context' do
        process_full_spy = class_spy(Payments::Successful::ProcessFull).as_stubbed_const

        expect(context).to be_success
        expect(process_full_spy).to have_received(:call) do |received_context|
          expect(received_context.payment[:id]).to eq(payment[:id])
        end
      end
    end

    context 'when payment is not partial' do
      let(:payment) do
        payment = Factory[
          :payment,
          renewal_invoice_id: renewal_invoice[:id],
          amount_cents: renewal_invoice[:amount_cents],
          status: 'pending'
        ]
        DB.relations['payments'].combine(:renewal_invoice).by_pk(payment[:id]).one
      end

      it 'runs Payments::Successful::ProcessFull with context' do
        process_full_spy = class_spy(Payments::Successful::ProcessFull).as_stubbed_const

        expect(context).to be_success
        expect(process_full_spy).to have_received(:call) do |received_context|
          expect(received_context.payment[:id]).to eq(payment[:id])
        end
      end
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

      it 'runs Payments::Successful::ProcessPartial with context' do
        process_full_spy = class_spy(Payments::Successful::ProcessPartial).as_stubbed_const

        expect(context).to be_success
        expect(process_full_spy).to have_received(:call) do |received_context|
          expect(received_context.payment[:id]).to eq(payment[:id])
        end
      end
    end
  end
end
