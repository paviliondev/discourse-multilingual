# name: discourse-multilingual
# about: Features to support multilingual forums
# version: 0.0.1
# url: https://github.com/angusmcleod/discourse-multilingual
# authors: Angus McLeod

register_asset 'stylesheets/multilingual.scss'

gem 'active_hash', '3.0.0'

if respond_to?(:register_svg_icon)
  register_svg_icon "language"
end

after_initialize do
  register_seedfu_fixtures(
    Rails.root.join(
      "plugins",
      "discourse-multilingual",
      "db",
      "fixtures"
    ).to_s
  )
  
  module ::Multilingual
    class Engine < ::Rails::Engine
      engine_name "multilingual"
      isolate_namespace Multilingual
    end
  end
  
  class ::Multilingual::Languages < ActiveHash::Base
    include ActiveModel::Serialization
  end
  
  languages = YAML.safe_load(File.read(File.join(
    Rails.root,
    'plugins',
    'discourse-multilingual',
    'config',
    'languages.yml'
  )))
  
  id = 0
  
  Multilingual::Languages.data = languages["languages"].map do |k, v|
    id = id + 1
    {
      id: id,
      code: k,
      name: v.last
    }
  end
  
  register_editable_user_custom_field :content_languages if defined? register_editable_user_custom_field
  register_editable_user_custom_field content_languages: [] if defined? register_editable_user_custom_field
  whitelist_public_user_custom_field :content_languages if defined? whitelist_public_user_custom_field

  class Multilingual::LanguageSerializer < ::ApplicationSerializer
    attributes :code, :name
  end
  
  class Multilingual::ContentController < ::ApplicationController
    def languages
      render_serialized(Multilingual::Languages.all.to_a, Multilingual::LanguageSerializer)
    end
  end
  
  Multilingual::Engine.routes.draw do
    get 'languages' => 'content#languages'
  end

  Discourse::Application.routes.append do
    mount ::Multilingual::Engine, at: 'multilingual'
  end
  
  TopicQuery.add_custom_filter(:content_language) do |result, query|
    if query.user && (content_languages = query.user.custom_fields['content_languages'])
      result.joins(:tags).where("lower(tags.name) in (?)", content_languages)
    else
      result
    end
  end
  
  class ::User
    def content_languages
      if content_languages = self.custom_fields['content_languages']
        [*content_languages]
      else
        []
      end
    end
  end
  
  add_to_serializer(:current_user, :content_languages) do
    if user_content_languages = object.content_languages
      user_content_languages.map do |code|
        Multilingual::LanguageSerializer.new(
          Multilingual::Languages.find_by(code: code),
          root: false
        )
      end
    end
  end
  
  DiscourseEvent.on(:user_updated) do |user|
    if user.content_languages.include? "none"
      user.custom_fields['content_languages'] = []
      user.save_custom_fields(true)
    end
  end
end