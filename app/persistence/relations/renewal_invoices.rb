# frozen_string_literal: true

module Persistence
  module Relations
    class RenewalInvoices < ROM::Relation[:sql]
      schema(:renewal_invoices, infer: true) do
        associations do
          belongs_to :subscriptions, as: :subscription
        end
      end
    end
  end
end
