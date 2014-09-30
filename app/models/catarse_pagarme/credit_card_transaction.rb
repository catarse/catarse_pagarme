module CatarsePagarme
  class CreditCardTransaction < TransactionBase
    def charge!
      self.transaction = PagarMe::Transaction.new(self.attributes)
      self.transaction.charge

      if self.transaction.status == 'refused'
        raise ::PagarMe::PagarMeError.new(I18n.t('projects.contributions.edit.transaction_error'))
      end

      change_contribution_state
      self.transaction
    end
  end
end
