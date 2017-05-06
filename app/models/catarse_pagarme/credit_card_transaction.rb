module CatarsePagarme
  class CreditCardTransaction < TransactionBase

    def charge!
      save_card = self.attributes.delete(:save_card)

      self.transaction = PagarMe::Transaction.new(self.attributes)

      unless payment.update_attributes({
        gateway: 'Pagarme',
        payment_method: payment_method })

        raise ::PagarMe::PagarMeError.new(
          payment.errors.messages.values.flatten.to_sentence)
      end

      self.transaction.charge

      #VerifyPagarmeWorker.perform_in(5.minutes, payment.key)

      change_payment_state

      if self.transaction.status == 'refused'
        raise ::PagarMe::PagarMeError.new(I18n.t('projects.contributions.edit.transaction_error'))
      end

      save_user_credit_card if save_card
      self.transaction
    end

    def save_user_credit_card
      card = self.transaction.card

      credit_card = self.user.credit_cards.find_or_initialize_by(card_key: card.id)
      credit_card.last_digits = card.last_digits
      credit_card.card_brand = card.brand

      credit_card.save!
    end

  end
end
