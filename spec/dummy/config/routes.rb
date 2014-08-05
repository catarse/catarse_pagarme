Rails.application.routes.draw do

  mount CatarsePagarme::Engine => "/catarse_pagarme"
end
