require "pagarme"

module CatarsePagarme
  class ApplicationController < ActionController::Base

    before_action :configure_pagarme

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
        :payment_method, :amount, :postback_url, 
        user: [ 
          bank_account_attributes: [
            :name, :account, :account_digit, :agency, 
            :agency_digit, :user_name, :user_document
          ] 
        ]
      ])
    end
  end
end
