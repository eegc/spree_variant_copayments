Spree::Core::Engine.routes.draw do
  resources :relations do
    collection do
      post :update_positions
    end
  end
end
