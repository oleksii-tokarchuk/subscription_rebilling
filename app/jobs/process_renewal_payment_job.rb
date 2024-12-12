# frozen_string_literal: true

class ProcessRenewalPaymentJob
  include Sidekiq::Job

  def perform(payment_id); end
end
