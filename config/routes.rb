CatarsePagarme::Engine.routes.draw do
  resources :pagarme, only: [], path: "payment/pagarme" do

    collection do
      post :ipn
    end

    member do
      get  :review
      post :pay_credit_card
      post :pay_slip
    end

  end
end
