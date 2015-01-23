module CatarsePagarme::FeeCalculatorConcern
  extend ActiveSupport::Concern

  included do

    def get_fee(payment_method, acquirer_name = nil)
      if payment_method == ::CatarsePagarme::PaymentType::SLIP
        CatarsePagarme.configuration.slip_tax.to_f
      else
        if acquirer_name == 'stone'
          self.contribution.installments > 1 ? tax_calc_for_installment(stone_tax) : tax_calc(stone_tax)
        else
          if self.transaction.card_brand == 'amex'
            self.contribution.installments > 1 ? tax_calc_for_installment(cielo_installment_amex_tax) : tax_calc(cielo_installment_not_amex_tax)
          else
            current_tax = self.transaction.card_brand == 'diners' ? installment_diners_tax : installment_not_diners_tax
            self.contribution.installments > 1 ? tax_calc_for_installment(current_tax) : tax_calc(cielo_tax)
          end
        end
      end
    end

    protected

    def tax_calc acquirer_tax
      ((self.contribution.value * pagarme_tax) + cents_fee).round(2) + (self.contribution.value * acquirer_tax).round(2)
    end

    def tax_calc_for_installment acquirer_tax
      (((self.contribution.installment_value * self.contribution.installments) * pagarme_tax) + cents_fee).round(2) + ((self.contribution.installment_value * acquirer_tax).round(2) * self.contribution.installments)
    end

    def cents_fee
      CatarsePagarme.configuration.credit_card_cents_fee.to_f
    end

    def pagarme_tax
      CatarsePagarme.configuration.pagarme_tax.to_f
    end

    def cielo_tax
      CatarsePagarme.configuration.cielo_tax.to_f
    end

    def stone_tax
      CatarsePagarme.configuration.stone_tax.to_f
    end

    def installment_diners_tax
      CatarsePagarme.configuration.cielo_installment_diners_tax.to_f
    end

    def installment_not_diners_tax
      CatarsePagarme.configuration.cielo_installment_not_diners_tax.to_f
    end

    def cielo_installment_amex_tax
      CatarsePagarme.configuration.cielo_installment_amex_tax.to_f
    end

    def cielo_installment_not_amex_tax
      CatarsePagarme.configuration.cielo_installment_not_amex_tax.to_f
    end

  end
end
