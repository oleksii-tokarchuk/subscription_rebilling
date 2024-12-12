# frozen_string_literal: true

class CreateRenewal
  include Interactor

  def call
    context.subscription = DB.relations['subscriptions'].fetch(context.subscription_id)

    DB.gateways[:default].transaction do
      create_renewal_invoice
      create_renewal_payment
      update_subscription_status
    end

    ProcessRenewalPaymentJob.perform_async(context.renewal_payment[:id])
  end

  private

  def create_renewal_invoice
    create_renewal_invoice = DB.relations['renewal_invoices'].command(:create)
    context.renewal_invoice = create_renewal_invoice.call(
      subscription_id: context.subscription[:id],
      amount_cents: context.subscription[:amount_cents],
      amount_cents_left: context.subscription[:amount_cents],
      invoiced_at: context.subscription[:next_renewal_at],
      status: 'pending'
    )
  end

  def create_renewal_payment
    create_renewal_payment = DB.relations['payments'].command(:create)
    context.renewal_payment = create_renewal_payment.call(
      renewal_invoice_id: context.renewal_invoice[:id],
      amount_cents: context.renewal_invoice[:amount_cents],
      status: 'pending'
    )
  end

  def update_subscription_status
    update_subscription = DB.relations['subscriptions'].by_pk(context.subscription[:id]).command(:update)
    update_subscription.call(status: 'pending')
  end
end
