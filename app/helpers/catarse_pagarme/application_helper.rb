module CatarsePagarme
  module ApplicationHelper

    def installments_for_select(contribution)
      installments = contribution.pagarme_delegator.get_installments['installments']

      collection = installments.map do |installment|
        installment_number = installment[0].to_i
        if installment_number <= CatarsePagarme.configuration.max_installments
          amount = installment[1]['installment_amount'] / 100.0
          [format_instalment_text(installment_number, amount), installment_number]
        end
      end

      collection.compact
    end

    def format_instalment_text(number, amount)
      [number, number_to_currency(amount, precision: 2)].join('x ')
    end

  end
end
