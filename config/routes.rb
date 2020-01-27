Discourse::Application.routes.append do
  mount ::Multilingual::Engine, at: 'multilingual'
  
  scope module: 'multilingual', constraints: AdminConstraint.new do
    get 'admin/multilingual' => 'admin#index'
    
    get 'admin/multilingual/languages' => 'admin_languages#index'
    get 'admin/multilingual/languages/:query' => 'admin_languages#index'
    put 'admin/multilingual/languages' => 'admin_languages#update'
    post 'admin/multilingual/languages.json' => 'admin_languages#upload'
    delete 'admin/multilingual/languages' => 'admin_languages#remove'
    
    get 'admin/multilingual/translations' => 'admin_translations#index'
    post 'admin/multilingual/translations.json' => 'admin_translations#upload'
    delete 'admin/multilingual/translations' => 'admin_translations#remove'
    
    get 'admin/multilingual/translations/download' => 'admin_translations#download'
  end
end