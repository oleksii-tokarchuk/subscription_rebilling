# frozen_string_literal: true

describe CreateRenewalJob do
  it { is_expected.to be_a(Sidekiq::Job) }

  describe '#perform' do
    let(:subscription_id) { rand(1..99) }

    it 'runs CreateRenewal for given subscription_id' do
      create_renewal_spy = class_spy(CreateRenewal).as_stubbed_const

      described_class.new.perform(subscription_id)

      expect(create_renewal_spy).to have_received(:call).with(subscription_id: subscription_id)
    end
  end
end
