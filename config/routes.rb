Spree::Core::Engine.routes.draw do
  namespace :admin do
    resources :copayment_relations, except: [:index, :new, :show, :edit] do
      collection do
        post :update_positions
      end
    end

    resources :products, only: [] do
      get :copayment_relations, on: :member
    end
  end
end
