PaperView::Engine.routes.draw do
  root "versions#index"

  resources :versions, only: :index
  resource :stats, only: :show
end
