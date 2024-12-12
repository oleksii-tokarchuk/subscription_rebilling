# frozen_string_literal: true

module Persistence
  module Relations
    class Payments < ROM::Relation[:sql]
      schema(:payments, infer: true)
    end
  end
end
