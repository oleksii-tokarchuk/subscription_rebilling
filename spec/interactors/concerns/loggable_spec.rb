# frozen_string_literal: true

describe Loggable do
  let(:logger) { instance_spy(Logger) }
  let(:dummy_interactor) do
    Class.new do
      include Interactor
      include Loggable

      def self.name
        'DummyInteractor'
      end

      def call
        context.called = 'called'
        raise 'some error' if context.raise_error
      end
    end
  end

  before { stub_const('LOGGER', logger) }

  context 'when interactor successful' do
    subject(:context) { dummy_interactor.call(raise_error: false) }

    it 'logs before .call' do
      expect(context).to be_success
      expect(logger).to have_received(:info).with(
        message: 'Start DummyInteractor. Context: raise_error = false'
      )
    end

    it 'calls interactor' do
      expect(context).to be_success
      expect(context.called).to eq('called')
    end

    it 'logs after .call' do
      expect(context).to be_success
      expect(logger).to have_received(:info).with(
        message: "Finished DummyInteractor Context: raise_error = false, called = 'called'"
      )
    end
  end

  context 'when interactor failed' do
    subject(:context) { dummy_interactor.call(raise_error: true) }

    it 'logs before .call' do
      expect(context).to be_failure
      expect(logger).to have_received(:info).with(
        message: 'Start DummyInteractor. Context: raise_error = true'
      )
    end

    it 'calls interactor' do
      expect(context).to be_failure
      expect(context.called).to eq('called')
    end

    it 'logs error' do
      expect(context).to be_failure
      expect(logger).to have_received(:error).with(
        message: "DummyInteractor failed. Context: raise_error = true, called = 'called'",
        error_class: RuntimeError,
        error_message: 'some error'
      )
    end
  end
end
