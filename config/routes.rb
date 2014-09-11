CatarsePagarme::Engine.routes.draw do
  resources :pagarme, only: [], path: "payment/pagarme" do

    member do
      get  :review
      post :ipn, to: 'notifications#create'
      post :pay_credit_card, to: 'credit_cards#create'
      post :pay_slip
      post :pay_with_subscription, to: 'subscriptions#create'
      put :pay_with_subscription, to: 'subscriptions#update'
    end

  end
end
