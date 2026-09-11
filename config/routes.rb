PaperView::Engine.routes.draw do
  root "versions#index"

  resources :versions, only: :index
end
