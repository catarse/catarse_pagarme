CatarsePagarme::Engine.routes.draw do
  resources :pagarme, only: [], path: "payment/pagarme" do

    member do
      get  :review
      post :pay_credit_card
      post :ipn, to: 'notifications#create'
      post :pay_slip
      post :pay_with_subscription
    end

  end
end
