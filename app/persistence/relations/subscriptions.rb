# frozen_string_literal: true

module Persistence
  module Relations
    class Subscriptions < ROM::Relation[:sql]
      schema(:subscriptions, infer: true)

      def for_renewal
        where { (status.is('paid')) & (next_renewal_at <= Date.today) }
      end
    end
  end
end
