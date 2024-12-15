# frozen_string_literal: true

module Persistence
  module Relations
    class Payments < ROM::Relation[:sql]
      schema(:payments, infer: true) do
        associations do
          belongs_to :renewal_invoices, as: :renewal_invoice
        end
      end

      struct_namespace Persistence::Entities
      auto_struct(true)
    end
  end
end
