# frozen_string_literal: true

class ProcessRenewalPaymentJob
  include Sidekiq::Job

  def perform(payment_id)
    Payments::Charge.call(payment_id: payment_id)
  end
end
