module CatarsePagarme
  class CreditCardsController < CatarsePagarme::ApplicationController
    MAX_SOFT_DESCRIPTOR_LENGTH = 13

    def create
      transaction = CreditCardTransaction.new(credit_card_attributes, payment).charge!

      render json: { payment_status: transaction.status }
    rescue PagarMe::PagarMeError => e
      render json: { payment_status: 'failed', message: e.message }
    end

    protected

    def credit_card_attributes
      contribution = payment.contribution
      phone_matches = contribution.address_phone_number.gsub(/[\s,-]/, '').match(/\((.*)\)(\d+)/)

      hash = {
        payment_method: 'credit_card',
        amount: delegator.value_with_installment_tax(get_installment),
        postback_url: ipn_pagarme_index_url(
          host: CatarsePagarme.configuration.host,
          subdomain: CatarsePagarme.configuration.subdomain,
          protocol: CatarsePagarme.configuration.protocol
        ),
        soft_descriptor: payment.project.permalink.gsub(/[\W\_]/, ' ')[0, MAX_SOFT_DESCRIPTOR_LENGTH],
        installments: get_installment,
        customer: {
          email: contribution.payer_email,
          name: contribution.payer_name,
          document_number: contribution.payer_document.gsub(/[-.\/_\s]/,''),
          address: {
            street: contribution.address_street,
            neighborhood: contribution.address_neighbourhood,
            zipcode: contribution.address_zip_code.gsub(/[-.]/, ''),
            street_number: contribution.address_number,
            complementary: contribution.address_complement
          },
          phone: {
            ddd: phone_matches[1],
            number: phone_matches[2]
          }
        },
        metadata: metadata_attributes
      }

      if params[:card_hash].present?
        hash[:card_hash] = params[:card_hash]
      else
        hash[:card_id] = params[:card_id]
      end

      if params[:save_card] === "true"
        hash[:save_card] = true
      end

      hash
    end

    def get_installment
      if payment.value.to_f < CatarsePagarme.configuration.minimum_value_for_installment.to_f
        1
      elsif params[:payment_card_installments].to_i > 0
        params[:payment_card_installments].to_i
      else
        1
      end
    end

  end
end
