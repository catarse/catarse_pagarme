module CatarsePagarme
  class PagarmeController < CatarsePagarme::ApplicationController

    skip_before_filter :force_http
    layout :false

    def ipn
    end

    def pay_credit_card
    end

    def pay_boleto
    def pay_slip
    end

  end
end
