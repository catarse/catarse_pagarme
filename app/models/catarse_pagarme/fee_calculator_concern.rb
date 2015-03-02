module CatarsePagarme::FeeCalculatorConcern
  extend ActiveSupport::Concern

  included do

    def get_fee
      return nil if self.contribution.payment_choice.blank? # We always depend on the payment_choice
      if self.contribution.payment_choice == ::CatarsePagarme::PaymentType::SLIP
        get_slip_fee
      else
        get_card_fee
      end
    end

    protected
    def get_slip_fee
      CatarsePagarme.configuration.slip_tax.to_f
    end

    def get_card_fee
      return nil if self.contribution.acquirer_name.blank? # Here we depend on the acquirer name
      if self.contribution.acquirer_name == 'stone'
        get_stone_fee
      else
        get_cielo_fee
      end
    end

    def get_stone_fee
      self.contribution.installments > 1 ? tax_calc_for_installment(stone_tax) : tax_calc(stone_tax)
    end

    def get_cielo_fee
      return nil if self.contribution.card_brand.blank? # Here we depend on the card_brand
      if self.contribution.card_brand == 'amex'
        get_cielo_fee_for_amex
      else
        get_cielo_fee_for_non_amex
      end
    end

    def get_cielo_fee_for_amex
      self.contribution.installments > 1 ? tax_calc_for_installment(cielo_installment_amex_tax) : tax_calc(cielo_installment_not_amex_tax)
    end

    def get_cielo_fee_for_non_amex
      current_tax = self.contribution.card_brand == 'diners' ? installment_diners_tax : installment_not_diners_tax
      self.contribution.installments > 1 ? tax_calc_for_installment(current_tax) : tax_calc(cielo_tax)
    end

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
