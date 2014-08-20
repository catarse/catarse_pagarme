module CatarsePagarme
  class SlipTransaction
    attr_accessor :attributes, :contribution, :user

    def initialize(attributes, contribution)
      self.attributes = attributes
      self.contribution = contribution
      self.user = contribution.user
      puts self.attributes.inspect
      build_default_bank_account
    end

    def charge!
      update_user_bank_account

      transaction = PagarMe::Transaction.new(self.attributes[:slip_payment])
      transaction.charge

      contribution_attrs = {
        payment_choice: PaymentType::SLIP,
        payment_service_fee: delegator.get_fee(PaymentType::SLIP),
        payment_id: transaction.id

      }
      contribution.update_attributes(contribution_attrs)

      delegator.change_status_by_transaction(transaction.status)
      return transaction
    end

    protected

    def update_user_bank_account
      self.user.update_attributes(self.attributes[:user])
      if self.user.errors.present?
        raise ::PagarMe::PagarMeError.new(self.user.errors.full_messages.to_sentence)
      end
    end

    def build_default_bank_account
      self.user.build_bank_account unless self.user.bank_account
    end

    def delegator
      self.contribution.pagarme_delegator
    end
  end
end
