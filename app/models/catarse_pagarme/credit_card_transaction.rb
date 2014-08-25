module CatarsePagarme
  class CreditCardTransaction < TransactionBase
    def charge!
      self.transaction = PagarMe::Transaction.new(self.attributes)
      self.transaction.charge

      change_contribution_state
      self.transaction
    end
  end
end
