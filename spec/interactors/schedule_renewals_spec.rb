# frozen_string_literal: true

describe ScheduleRenewals do
  subject(:context) { described_class.call }

  let!(:for_renewal) { Array.new(2) { Factory[:subscription, :for_renewal] } }

  before do
    Factory[:subscription, :paid]
    Factory[:subscription, :pending]
    Factory[:subscription, :partially_paid]
    Factory[:subscription, :failed]
  end

  describe '.call' do
    it "schedules CreateRenewalJob for 'for_renewal' subscriptions" do
      expect { context }.to change(CreateRenewalJob.jobs, :size).from(0).to(2)
      expect(CreateRenewalJob).to have_enqueued_sidekiq_job(for_renewal[0][:id]).immediately
      expect(CreateRenewalJob).to have_enqueued_sidekiq_job(for_renewal[1][:id]).immediately
    end
  end
end
