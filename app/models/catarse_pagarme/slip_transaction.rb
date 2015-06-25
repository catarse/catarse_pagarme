module CatarsePagarme
  class SlipTransaction < TransactionBase
    def charge!
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
