# name: discourse-multilingual
# about: Features to support multilingual forums
# version: 0.1.0
# url: https://github.com/angusmcleod/discourse-multilingual
# authors: Angus McLeod

enabled_site_setting :multilingual_enabled

register_asset 'stylesheets/multilingual.scss'

if respond_to?(:register_svg_icon)
  register_svg_icon "language"
  register_svg_icon "translate"
end

after_initialize do    
  [
    '../lib/multilingual/engine.rb',
    '../lib/multilingual/language/content_tag.rb',
    '../lib/multilingual/language/content.rb',
    '../lib/multilingual/language/interface.rb',
    '../lib/multilingual/language/locale.rb',
    '../lib/multilingual/language.rb',
    '../lib/multilingual/translation/file.rb',
    '../lib/multilingual/translation.rb',
    '../lib/i18n.rb',
    '../lib/js_locale_helper.rb',
    '../config/routes.rb',
    '../models/multilingual/category_list.rb',
    '../models/multilingual/locale_site_setting.rb',
    '../serializers/multilingual/basic_language_serializer.rb',
    '../serializers/multilingual/language_serializer.rb',
    '../serializers/multilingual/translation_serializer.rb',
    '../controllers/multilingual/admin_controller.rb',
    '../controllers/multilingual/admin_languages_controller.rb',
    '../controllers/multilingual/admin_translations_controller.rb'
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
    Multilingual::Content.all
  end
  
  add_to_serializer(:site, :content_languages) do
    ActiveModel::ArraySerializer.new(
      object.content_languages,
      each_serializer: Multilingual::BasicLanguageSerializer,
      root: false
    ).as_json
  end
  
  add_to_serializer(:current_user, :content_languages) do
    if user_content_languages = object.content_languages
      user_content_languages.map do |code|
        Multilingual::BasicLanguageSerializer.new(
          Multilingual::Language.get(code).first,
          root: false
        )
      end
    end
  end
  
  add_to_serializer(:topic_view, :content_language_tags) do
    Multilingual::ContentTag.filter(topic.tags).map(&:name)
  end
  
  add_to_serializer(:topic_list_item, :content_language_tags) do
    Multilingual::ContentTag.filter(topic.tags).map(&:name)
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
  
  add_to_class(:guardian, :topic_requires_language_tag) do
    SiteSetting.multilingual_enabled &&
    (SiteSetting.multilingual_require_language_tag === 'yes' ||
    (!is_staff? && SiteSetting.multilingual_require_language_tag === 'non-staff'))
  end
  
  add_class_method(:discourse_tagging, :validate_require_language_tag) do |guardian, topic, tag_names|
    if guardian.topic_requires_language_tag && (tag_names.blank? || 
       !Tag.where(name: tag_names).where("id IN (
          #{DiscourseTagging::TAG_GROUP_TAG_IDS_SQL}
          AND tg.name = '#{Multilingual::ContentTag::GROUP_NAME}'
        )").exists?)

      topic.errors.add(:base,
        I18n.t(
         "tags.required_tags_from_group",
         count: 1,
         tag_group_name: Multilingual::ContentTag::GROUP_NAME
        )
      )
      
      false
    else
      true
    end
  end
  
  DiscourseTagging.singleton_class.send(
    :alias_method,
    :tag_topic_by_names_core,
    :tag_topic_by_names
  )
  
  add_class_method(:discourse_tagging, :tag_topic_by_names) do |topic, guardian, tag_names_arg, append: false|
    return false unless validate_require_language_tag(guardian, topic, tag_names_arg)
    tag_topic_by_names_core(topic, guardian, tag_names_arg, append: append)
  end
  
  DiscourseTagging.singleton_class.send(
    :alias_method,
    :filter_allowed_tags_core,
    :filter_allowed_tags
  )
  
  add_class_method(:discourse_tagging, :filter_allowed_tags) do |guardian, opts = {}|
    result = filter_allowed_tags_core(guardian, opts)
          
    if opts[:for_input]
      result.select do |tag|
        Multilingual::ContentTag.names.exclude? tag.name
      end
    else
      result
    end
  end
  
  add_to_serializer(:site_category, :name) do
    Multilingual::Translation.category_names[slug] || super()
  end
  
  Multilingual::Language.setup
end