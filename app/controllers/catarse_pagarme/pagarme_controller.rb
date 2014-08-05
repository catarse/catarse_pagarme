module CatarsePagarme
  class PagarmeController < ApplicationController

    skip_before_filter :force_http
    layout :false

    def ipn
    end

    def pay_credit_card
    end

    def pay_boleto
    end

  end
end
