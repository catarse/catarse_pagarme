module CatarsePagarme
  class SlipTransaction < TransactionBase
    def charge!
      unless payment.update_attributes({
        gateway: 'Pagarme',
        payment_method: payment_method})

        raise ::PagarMe::PagarMeError.new(
          payment.errors.messages.values.flatten.to_sentence)
      end

      self.transaction = PagarMe::Transaction.new(self.attributes)
      self.transaction.charge

      change_payment_state
      self.transaction
    end

    def payment_method
      PaymentType::SLIP
    end
  end
end
