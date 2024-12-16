# frozen_string_literal: true

module Payments
  module Successful
    class ProcessPartial
      include Interactor
      include Loggable

      FINAL_PAYMENT_DELAY = 7 * 24 * 60 * 60 # 1 week

      def call
        DB.gateways[:default].transaction do
          update_payment
          update_invoice
          update_subscription
          create_final_payment
        end

        ProcessRenewalPaymentJob.perform_in(FINAL_PAYMENT_DELAY, context.final_payment[:id])
      end

      private

      def update_payment
        update_payment = DB.relations['payments'].by_pk(context.payment_id).command(:update)
        update_payment.call(paid_at: Time.now, status: 'paid')
      end

      def update_invoice
        update_invoice = DB.relations['renewal_invoices'].by_pk(context.payment[:renewal_invoice_id]).command(:update)
        update_invoice.call(status: 'partially_paid', amount_cents_left: amount_cents_left)
      end

      def update_subscription
        update_subscription =
          DB.relations['subscriptions'].by_pk(context.payment[:renewal_invoice][:subscription_id]).command(:update)
        update_subscription.call(status: 'partially_paid')
      end

      def create_final_payment
        create_final_payment = DB.relations['payments'].command(:create)
        context.final_payment = create_final_payment.call(
          renewal_invoice_id: context.payment[:renewal_invoice_id],
          amount_cents: amount_cents_left,
          is_partial: true,
          status: 'pending'
        )
      end

      def amount_cents_left
        @amount_cents_left ||= context.payment[:renewal_invoice][:amount_cents_left] - context.payment[:amount_cents]
      end
    end
  end
end
