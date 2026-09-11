PaperView::Engine.routes.draw do
  resources :versions, only: %i[index show] do
    post :revert, on: :member
  end

  root to: "versions#index"
end
