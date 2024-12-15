# frozen_string_literal: true

module Payments
  module Successful
    class ProcessFull
      include Interactor
      include Loggable

      def call
        DB.gateways[:default].transaction do
          update_payment
          update_invoice
          update_subscription
        end
      end

      private

      def update_payment
        update_payment = DB.relations['payments'].by_pk(context.payment_id).command(:update)
        update_payment.call(paid_at: DateTime.now, status: 'paid')
      end

      def update_invoice
        update_invoice = DB.relations['renewal_invoices'].by_pk(context.payment[:renewal_invoice_id]).command(:update)
        update_invoice.call(status: 'paid', amount_cents_left: 0)
      end

      def update_subscription
        update_subscription =
          DB.relations['subscriptions'].by_pk(context.payment[:renewal_invoice][:subscription_id]).command(:update)
        update_subscription.call(
          status: 'paid',
          next_renewal_at: context.payment[:renewal_invoice][:invoiced_at].next_month
        )
      end
    end
  end
end
