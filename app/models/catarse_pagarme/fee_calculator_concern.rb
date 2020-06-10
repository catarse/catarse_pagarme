module CatarsePagarme::FeeCalculatorConcern
  extend ActiveSupport::Concern

  included do

    def get_fee
      return nil if self.payment.payment_method.blank? # We always depend on the payment_choice

      transaction = PagarMe::Transaction.find(self.payment.gateway_id)
      payables = transaction.payables
      cost = transaction.cost.to_f / 100.00
      payables_fee = payables.to_a.sum(&:fee).to_f / 100.00

      if self.payment.payment_method == ::CatarsePagarme::PaymentType::SLIP
        payables_fee == 0 ? cost : payables_fee
      else
        cost + payables_fee
      end
    end
  end
end
