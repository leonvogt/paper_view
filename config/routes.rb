PaperView::Engine.routes.draw do
  resources :versions, only: :index

  root to: "versions#index"
end
