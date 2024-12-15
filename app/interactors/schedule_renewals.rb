# frozen_string_literal: true

class ScheduleRenewals
  include Interactor
  include Loggable

  def call
    DB.relations['subscriptions'].for_renewal.each_batch do |batch|
      batch.each { CreateRenewalJob.perform_async(_1[:id]) }
    end
  end
end
