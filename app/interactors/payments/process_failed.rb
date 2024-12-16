# frozen_string_literal: true

module Payments
  class ProcessFailed
    include Interactor
    include Loggable

    def call
      DB.gateways[:default].transaction do
        fail_payment
        unless subscription_partially_paid?
          fail_invoice
          fail_subscription
        end
      end
    end

    private

    def fail_payment
      update_payment = DB.relations['payments'].by_pk(context.payment_id).command(:update)
      update_payment.call(paid_at: Time.now, status: 'failed')
    end

    def fail_invoice
      update_invoice = DB.relations['renewal_invoices'].by_pk(context.payment[:renewal_invoice_id]).command(:update)
      update_invoice.call(status: 'failed')
    end

    def fail_subscription
      update_subscription =
        DB.relations['subscriptions'].by_pk(context.payment[:renewal_invoice][:subscription_id]).command(:update)
      update_subscription.call(status: 'failed')
    end

    def subscription_partially_paid?
      context.payment.final?
    end
  end
end
