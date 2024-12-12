# frozen_string_literal: true

class ScheduleRenewals
  include Interactor

  def call
    DB.relations['subscriptions'].for_renewal.each do |subscription|
      CreateRenewalJob.perform_async(subscription[:id])
    end
  end
end
