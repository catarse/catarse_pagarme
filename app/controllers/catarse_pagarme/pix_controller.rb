require 'weekdays'

module CatarsePagarme
  class PixController < CatarsePagarme::ApplicationController

    def create
      transaction = PixTransaction.new(pix_attributes, payment).charge!

      render json: { pix_qrcode: transaction.pix_qrcode, payment_status: transaction.status, gateway_data: payment.gateway_data }
    rescue PagarMe::PagarMeError => e
      raven_capture(e)
      render json: { pix_qrcode: nil, payment_status: 'failed', message: e.message }
    end

    def update
      payment.generating_second_pix = true
      transaction = PixTransaction.new(pix_attributes, payment).charge!
      respond_to do |format|
        format.html { redirect_to transaction.pix_qrcode }
        format.json do
          { pix_qrcode: transaction.pix_qrcode }
        end
      end
    end

    def pix_data
      render json: {pix_expiration_date: payment.pix_expiration_date.to_date}
    end

    protected

    def pix_attributes
      {
        payment_method: 'pix',
        amount: delegator.value_for_transaction,
        pix_expiration_date: payment.pix_expiration_date,
        pix_additional_fields: {
          email: payment.user.email,
          name: payment.user.name,
          type: payment.user.account_type == 'pf' ? 'individual' : 'corporation',
          number: document_number,
          second_pix: payment.generating_second_pix.to_s
        }
      }
    end

    def document_number
      international? ? '00000000000' : contribution.user.cpf.gsub(/[-.\/_\s]/,'')
    end

    def international?
      contribution.international?
    end
  end
end
