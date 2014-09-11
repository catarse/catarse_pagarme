module CatarsePagarme
  class PagarmeController < CatarsePagarme::ApplicationController

    def review
      contribution
      current_user.build_bank_account unless current_user.bank_account
    end

  end
end
