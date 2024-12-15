# frozen_string_literal: true

module Loggable
  def self.included(base)
    base.class_eval do
      around do |interactor|
        context_to_s = lambda do
          string = []
          context.each_pair do |key, value|
            string << "#{key} = #{value}"
          end
          string.join(', ')
        end

        LOGGER.info(message: "Start #{self.class.name}. Context: #{context_to_s.call}")
        interactor.call
        LOGGER.info(message: "Finished #{self.class.name} Context: #{context_to_s.call}")
      rescue StandardError => e
        LOGGER.error(
          message: "#{self.class.name} failed. Context: #{context_to_s.call}",
          error_class: e.class,
          error_message: e.message
        )
        context.fail!
      end
    end
  end
end
