# name: discourse-multilingual
# about: Features to support multilingual forums
# version: 0.0.1
# url: https://github.com/angusmcleod/discourse-multilingual
# authors: Angus McLeod

enabled_site_setting :multilingual_enabled

register_asset 'stylesheets/multilingual.scss'

if respond_to?(:register_svg_icon)
  register_svg_icon "language"
  register_svg_icon "translate"
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
    
  [
    '../jobs/update_language_data.rb',
    '../lib/multilingual/engine.rb',
    '../lib/multilingual/languages.rb',
    '../lib/multilingual/tagging_extension.rb',
    '../lib/multilingual/category_list_extension.rb'
  ].each do |path|
    load File.expand_path(path, __FILE__)
  end
  
  if defined? register_editable_user_custom_field
    register_editable_user_custom_field :content_languages 
    register_editable_user_custom_field content_languages: []
  end
  
  if defined? whitelist_public_user_custom_field
    whitelist_public_user_custom_field :content_languages
  end

  Discourse::Application.routes.append do
    mount ::Multilingual::Engine, at: 'multilingual'
  end
  
  TopicQuery.add_custom_filter(:content_language) do |result, query|
    if query.user && 
      (content_languages = query.user.custom_fields['content_languages'])
      result.joins(:tags).where("lower(tags.name) in (?)", content_languages)
    else
      result
    end
  end
  
  add_to_class(:user, :content_languages) do
    if content_languages = self.custom_fields['content_languages']
      [*content_languages]
    else
      []
    end
  end
  
  add_to_class(:site, :content_languages) do
    Multilingual::Language.all
  end
  
  class Multilingual::LanguageSerializer < ::ApplicationSerializer
    attributes :code, :name
  end
  
  add_to_serializer(:site, :content_languages) do
    ActiveModel::ArraySerializer.new(
      object.content_languages,
      each_serializer: Multilingual::LanguageSerializer,
      root: false
    ).as_json
  end
  
  add_to_serializer(:current_user, :content_languages) do
    if user_content_languages = object.content_languages
      user_content_languages.map do |code|
        Multilingual::LanguageSerializer.new(
          Multilingual::Language.get(code).first,
          root: false
        )
      end
    end
  end
  
  add_to_serializer(:topic_view, :language_tags) do
    Multilingual::Languages.tags_for(topic).map(&:name)
  end
  
  add_to_serializer(:topic_list_item, :language_tags) do
    Multilingual::Languages.tags_for(topic).map(&:name)
  end
  
  on(:user_updated) do |user|
    if user.content_languages.include? "none"
      user.custom_fields['content_languages'] = []
      user.save_custom_fields(true)
    end
  end
  
  on(:before_create_topic) do |topic, creator|
    if !DiscourseTagging.validate_require_language_tag(
        creator.guardian,
        topic,
        creator.opts[:tags]
      )
      creator.rollback_from_errors!(topic)
    end
  end
end