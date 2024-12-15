# frozen_string_literal: true

module Payments
  module Successful
    class Process
      include Interactor
      include Loggable

      def call
        if context.payment.final? || !context.payment[:is_partial]
          Payments::Successful::ProcessFull.call(context)
        else
          Payments::Successful::ProcessPartial.call(context)
        end
      end
    end
  end
end