
  resources :projects do 
    resources :service_contracts do
      member do
        get :timelog
      end
    end
  end

  resources :service_contracts do
    member do
      get :timelog
    end
    collection do 
      get 'autocomplete'
      get 'bulk_edit'
      post 'bulk_update'
      get 'context_menu'
    end
  end
