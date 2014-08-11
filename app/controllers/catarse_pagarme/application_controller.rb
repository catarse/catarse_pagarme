require "pagarme"

module CatarsePagarme
  class ApplicationController < ActionController::Base

    before_action :configure_pagarme

    protected
    def configure_pagarme
      PagarMe.api_key = CatarsePagarme.configuration.api_key
    end

  end
end
