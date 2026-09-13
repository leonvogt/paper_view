PaperView::Engine.routes.draw do
  root "versions#index"

  resources :versions, only: :index
  resource :stats, only: :show

  get "turbo-:digest.js", to: PaperView::TurboAsset, as: :turbo_asset
end
