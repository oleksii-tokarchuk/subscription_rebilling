# frozen_string_literal: true

module Persistence
  module Entities
    class Payment < ROM::Struct
      def final?
        is_partial && amount_cents == renewal_invoice.amount_cents_left
      end
    end
  end
end
