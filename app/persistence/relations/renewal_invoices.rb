# frozen_string_literal: true

module Persistence
  module Relations
    class RenewalInvoices < ROM::Relation[:sql]
      schema(:renewal_invoices, infer: true)
    end
  end
end
