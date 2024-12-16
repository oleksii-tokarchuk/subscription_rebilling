# frozen_string_literal: true

module Payments
  class ProcessInsufficientFunds
    include Interactor
    include Loggable

    REDUCTION_RATES = [0.75, 0.5, 0.25].freeze
    PAYMENT_DELAY = 60 # 1 minute

    def call
      DB.gateways[:default].transaction do
        update_payment
        if retries_with_reduced_amount_left?
          create_partial_payment
        elsif !subscription_partially_paid?
          fail_invoice
          fail_subscription
        end
      end

      ProcessRenewalPaymentJob.perform_in(PAYMENT_DELAY, context.partial_payment[:id]) if context.partial_payment
    end

    private

    def update_payment
      update_payment = DB.relations['payments'].by_pk(context.payment_id).command(:update)
      update_payment.call(paid_at: Time.now, status: 'insufficient_funds')
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

    def create_partial_payment
      create_partial_payment = DB.relations['payments'].command(:create)
      context.partial_payment = create_partial_payment.call(
        renewal_invoice_id: context.payment[:renewal_invoice_id],
        amount_cents: (context.payment[:renewal_invoice][:amount_cents] * reduction_rate).ceil,
        is_partial: true,
        status: 'pending'
      )
    end

    def reduction_rate
      @reduction_rate ||= begin
        partial_payment_sequence_number =
          if context.payment[:is_partial]
            DB.relations['payments']
              .where(is_partial: true, renewal_invoice_id: context.payment[:renewal_invoice_id]).count
          else
            0
          end
        REDUCTION_RATES[partial_payment_sequence_number]
      end
    end

    def retries_with_reduced_amount_left?
      !reduction_rate.nil?
    end

    def subscription_partially_paid?
      context.payment.final?
    end
  end
end
