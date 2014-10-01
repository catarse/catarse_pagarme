require "pagarme"

module CatarsePagarme
  class ApplicationController < ActionController::Base

    before_filter :authenticate_user!
    before_filter :configure_pagarme
    skip_before_filter :force_http
    layout :false

    protected
    def configure_pagarme
      PagarMe.api_key = CatarsePagarme.configuration.api_key
    end

    def authenticate_user!
      unless defined?(current_user) && current_user
        raise Exception.new('invalid user')
      end
    end

    def permited_attrs(attributes)
      attrs = ActionController::Parameters.new(attributes)
      attrs.permit([
        slip_payment: [:payment_method, :amount, :postback_url,
                       customer: [:name, :email]
        ],
        user: [
          bank_account_attributes: [
            :name, :account, :account_digit, :agency,
            :agency_digit, :owner_name, :owner_document
          ]
        ]
      ])
    end

    def contribution
      conditions = {id: params[:id] }

      unless params[:controller] == 'catarse_pagarme/notifications'
        conditions.merge!({user_id: current_user.id}) unless current_user.admin
      end

      @contribution ||= PaymentEngines.find_payment(conditions)
    end

    def delegator
      contribution.pagarme_delegator
    end
  end
end
