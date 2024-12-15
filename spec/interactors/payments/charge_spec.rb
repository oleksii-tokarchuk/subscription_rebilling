# frozen_string_literal: true

describe Payments::Charge do
  subject(:context) { described_class.call(payment_id: payment[:id]) }

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
    Factory[
      :payment,
      renewal_invoice_id: renewal_invoice[:id],
      amount_cents: renewal_invoice[:amount_cents],
      status: 'pending'
    ]
  end

  before do
    response = instance_double(Net::HTTPOK, body: api_response.to_json)
    allow(Net::HTTP).to receive(:post).with(
      URI("#{ENV.fetch('PAYMENT_GATEWAY_URL')}/paymentIntents/create"),
      {
        subscription_id: subscription[:id],
        amount: payment[:amount_cents]
      }.to_json,
      'Content-Type' => 'application/json'
    ).and_return(response)
  end

  describe '.call' do
    context "when api response is 'success'" do
      let(:api_response) { { 'status' => 'success' } }

      it 'runs Payments::Successful::Process with context' do
        process_successful_spy = class_spy(Payments::Successful::Process).as_stubbed_const

        expect(context).to be_success
        expect(process_successful_spy).to have_received(:call) do |received_context|
          expect(received_context.payment[:id]).to eq(payment[:id])
        end
      end
    end

    context "when api response is 'insufficient_funds'" do
      let(:api_response) { { 'status' => 'insufficient_funds' } }

      it 'runs Payments::ProcessInsufficientFunds with context' do
        process_successful_spy = class_spy(Payments::ProcessInsufficientFunds).as_stubbed_const

        expect(context).to be_success
        expect(process_successful_spy).to have_received(:call) do |received_context|
          expect(received_context.payment[:id]).to eq(payment[:id])
        end
      end
    end

    context "when api response is 'failed'" do
      let(:api_response) { { 'status' => 'failed' } }

      it 'runs Payments::ProcessFailed with context' do
        process_successful_spy = class_spy(Payments::ProcessFailed).as_stubbed_const

        expect(context).to be_success
        expect(process_successful_spy).to have_received(:call) do |received_context|
          expect(received_context.payment[:id]).to eq(payment[:id])
        end
      end
    end

    context 'when error is raised during api call' do
      let(:api_response) { { 'status' => 'failed' } }

      before { allow(Net::HTTP).to receive(:post).and_raise }

      it 'runs Payments::ProcessFailed with context' do
        process_successful_spy = class_spy(Payments::ProcessFailed).as_stubbed_const

        expect(context).to be_success
        expect(process_successful_spy).to have_received(:call) do |received_context|
          expect(received_context.payment[:id]).to eq(payment[:id])
        end
      end
    end

    context 'when api response is unexpected' do
      let(:api_response) { { 'status' => 'random' } }

      it 'fails context' do
        expect(context).to be_failure
      end
    end
  end
end
