# frozen_string_literal: true

describe ProcessRenewalPaymentJob do
  it { is_expected.to be_a(Sidekiq::Job) }

  describe '#perform' do
    let(:payment_id) { rand(1..99) }

    it 'runs Payments::Charge for given payment_id' do
      payment_charge_spy = class_spy(Payments::Charge).as_stubbed_const

      described_class.new.perform(payment_id)

      expect(payment_charge_spy).to have_received(:call).with(payment_id: payment_id)
    end
  end
end
