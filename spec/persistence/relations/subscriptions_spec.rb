# frozen_string_literal: true

describe Persistence::Relations::Subscriptions do
  describe '#for_renewal' do
    subject(:result) { DB.relations[:subscriptions].for_renewal }

    let!(:for_renewal) { Array.new(2) { Factory[:subscription, :for_renewal] } }

    before do
      Factory[:subscription, :paid]
      Factory[:subscription, :pending]
      Factory[:subscription, :partially_paid]
      Factory[:subscription, :failed]
    end

    it "returns subscriptions with a 'paid' status and a renewal date on or before today" do
      expect(result.map { _1[:id] }).to match_array(for_renewal.map { _1[:id] })
    end
  end
end
