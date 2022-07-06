# frozen_string_literal: true
Discourse::Application.routes.append do
  mount ::Multilingual::Engine, at: 'multilingual'

  scope module: 'multilingual', constraints: AdminConstraint.new do
    get 'admin/multilingual' => 'admin#index'

    get 'admin/multilingual/languages' => 'admin_languages#list'
    put 'admin/multilingual/languages' => 'admin_languages#update'
    post 'admin/multilingual/languages' => 'admin_languages#upload'
    delete 'admin/multilingual/languages' => 'admin_languages#remove'

    get 'admin/multilingual/translations' => 'admin_translations#list'
    post 'admin/multilingual/translations' => 'admin_translations#upload'
    delete 'admin/multilingual/translations' => 'admin_translations#remove'

    get 'admin/multilingual/translations/download' => 'admin_translations#download'
  end

  delete 'tag_groups/:id/content-tags' => 'tag_groups#destroy_content_tags'
  put 'tag_groups/:id/content-tags' => 'tag_groups#update_content_tags'
end
