# frozen_string_literal: true

module Payments
  class Charge
    include Interactor
    include Loggable

    def call
      context.payment = DB.relations['payments'].combine(:renewal_invoice).by_pk(context.payment_id).one

      charge

      case context.charge_result['status']
      when 'success' then Payments::Successful::Process.call(context)
      when 'insufficient_funds' then Payments::ProcessInsufficientFunds.call(context)
      when 'failed' then Payments::ProcessFailed.call(context)
      else
        LOGGER.error(message: "#{self.class.name} unknown charge result status for payment_id=#{context.payment_id}")
        context.fail!
      end
    end

    private

    def charge
      response = Net::HTTP.post(
        URI("#{ENV.fetch('PAYMENT_GATEWAY_URL')}/paymentIntents/create"),
        {
          subscription_id: context.payment[:renewal_invoice][:subscription_id],
          amount: context.payment[:amount_cents]
        }.to_json,
        'Content-Type' => 'application/json'
      )
      context.charge_result = JSON.parse(response.body)
    rescue StandardError => e
      LOGGER.error(
        message: "#{self.class.name} failed for payment_id=#{context.payment_id}",
        error_class: e.class,
        error_message: e.message
      )
      context.charge_result = { 'status' => 'failed' }
    end
  end
end
