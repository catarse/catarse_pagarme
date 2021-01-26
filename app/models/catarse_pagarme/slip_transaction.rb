module CatarsePagarme
  class SlipTransaction < TransactionBase
    def charge!
      unless payment.update(
        gateway: 'Pagarme',
        payment_method: payment_method
      )

        raise ::PagarMe::PagarMeError.new(
          payment.errors.messages.values.flatten.to_sentence)
      end

      self.transaction = PagarMe::Transaction.new(
        self.attributes.merge(payment_method: 'boleto', async: false)
      )

      if payment.contribution.project.mode == 'flex'
        self.transaction.attributes['amount'] = amount_with_fee
      end

      self.transaction.charge

      change_payment_state
      self.transaction
    end

    def payment_method
      PaymentType::SLIP
    end

    def amount_with_fee
      self.transaction.attributes['amount'] + pagarme_fee
    end

    def pagarme_fee
      PagarMe::Payable.all(status: 'paid',
                          payment_method: 'boleto',
                          count: 1).first.fee
    end
  end
end
