module CatarsePagarme
  class CreditCardBaseController < CatarsePagarme::ApplicationController

    protected

    def charge_with_class(kclass)
      transaction = kclass.new(credit_card_attributes, contribution).charge!

      render json: { payment_status: transaction.status }
    rescue Exception => e
      render json: { payment_status: 'failed', message: e.message }
    end

    def splited_month_and_year
      params[:payment_card_date].split('/')
    rescue
      [0, 0]
    end

    def get_installment
      if contribution.value < CatarsePagarme.configuration.minimum_value_for_installment
        1
      elsif params[:payment_card_installments].to_i > 0
        params[:payment_card_installments].to_i
      else
        1
      end
    end

    def credit_card_attributes
      {
        payment_method: 'credit_card',
        card_number: params[:payment_card_number],
        card_holder_name: params[:payment_card_name],
        card_expiration_month: splited_month_and_year[0],
        card_expiration_year: splited_month_and_year[1],
        card_cvv: params[:payment_card_source],
        amount: delegator.value_with_installment_tax(get_installment),
        postback_url: ipn_pagarme_url(contribution, host: CatarsePagarme.configuration.host, subdomain: CatarsePagarme.configuration.subdomain),
        installments: get_installment,
        customer: {
          email: contribution.user.email,
          name: contribution.user.name
        }
      }
    end
  end
end
