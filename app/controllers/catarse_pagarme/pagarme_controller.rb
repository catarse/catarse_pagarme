module CatarsePagarme
  class PagarmeController < ApplicationController

    skip_before_filter :force_http
    layout :false

    def ipn
    end

    def pay
    end

  end
end
