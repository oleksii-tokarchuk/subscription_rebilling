# frozen_string_literal: true

class CreateRenewalJob
  include Sidekiq::Job

  def perform(subscription_id)
    CreateRenewal.call(subscription_id: subscription_id)
  end
end
