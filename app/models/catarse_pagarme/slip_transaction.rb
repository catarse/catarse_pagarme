module CatarsePagarme
  class SlipTransaction < TransactionBase
    def initialize(attributes, contribution)
      super
      build_default_bank_account
    end

    def charge!
      update_user_bank_account

      self.transaction = PagarMe::Transaction.new(self.attributes)
      self.transaction.charge

      change_contribution_state

      self.transaction
    end

    def payment_method
      PaymentType::SLIP
    end

    protected

    def update_user_bank_account
      self.user.update_attributes(self.attributes.delete(:user))

      if self.user.errors.present?
        raise ::PagarMe::PagarMeError.new(self.user.errors.full_messages.to_sentence)
      end
    end

    def build_default_bank_account
      self.user.build_bank_account unless self.user.bank_account
    end
  end
end
