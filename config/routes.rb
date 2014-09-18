CatarsePagarme::Engine.routes.draw do
  resources :pagarme, only: [], path: "payment/pagarme" do

    member do
      get  :review
      put :second_slip, to: 'slip#update'
      post :ipn, to: 'notifications#create'
      post :pay_credit_card, to: 'credit_cards#create'
      post :pay_slip, to: 'slip#create'
      post :pay_with_subscription, to: 'subscriptions#create'
      put :pay_with_subscription, to: 'subscriptions#update'
    end

  end
end
