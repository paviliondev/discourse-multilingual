# name: discourse-multilingual
# about: Features to support multilingual forums
# version: 0.1.0
# url: https://github.com/angusmcleod/discourse-multilingual
# authors: Angus McLeod

enabled_site_setting :multilingual_enabled

register_asset 'stylesheets/common/multilingual.scss'
register_asset 'stylesheets/mobile/multilingual.scss', :mobile

if respond_to?(:register_svg_icon)
  register_svg_icon "language"
  register_svg_icon "translate"
  register_svg_icon "save"
end

after_initialize do    
  %w[
    ../lib/multilingual/engine.rb
    ../lib/multilingual/cache.rb
    ../lib/multilingual/language/content_tag.rb
    ../lib/multilingual/language/content.rb
    ../lib/multilingual/language/interface.rb
    ../lib/multilingual/language/locale.rb
    ../lib/multilingual/language.rb
    ../lib/multilingual/translation/file.rb
    ../lib/multilingual/translation.rb
    ../config/routes.rb
    ../app/serializers/multilingual/basic_language_serializer.rb
    ../app/serializers/multilingual/language_serializer.rb
    ../app/serializers/multilingual/translation_file_serializer.rb
    ../app/controllers/multilingual/admin_controller.rb
    ../app/controllers/multilingual/admin_languages_controller.rb
    ../app/controllers/multilingual/admin_translations_controller.rb
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
    if query.user && query.user.content_languages.any?
      result.joins(:tags).where("lower(tags.name) in (?)", query.user.content_languages)
    else
      result
    end
  end
    
  add_to_class(:user, :effective_locale) do
    if SiteSetting.allow_user_locale &&
       self.locale.present? &&
       Multilingual::Interface.enabled?(self.locale)
      self.locale
    else
      SiteSetting.default_locale
    end
  end
  
  add_to_class(:user, :content_languages) do
    content_languages = self.custom_fields['content_languages'] || []
    [*content_languages].select { |l| Multilingual::Content.enabled?(l) }
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
  
  add_class_method(:locale_site_setting, :valid_value?) do |val|
    supported_locales.include?(val) && Multilingual::Interface.enabled?(val)
  end
  
  LocaleSiteSetting.singleton_class.send(:alias_method, :values_core, :values)

  add_class_method(:locale_site_setting, :values) do
    @values ||= values_core.select { |v| Multilingual::Interface.enabled?(v[:locale]) }
  end
  
  I18n.singleton_class.send(:alias_method, :ensure_all_loaded_core!, :ensure_all_loaded!)
  I18n.singleton_class.send(:alias_method, :available_locales_core, :available_locales)
  
  add_class_method(:i18n, :ensure_all_loaded!) do
    ensure_all_loaded_core!
    Multilingual::Translation.reset_server!
    Multilingual::Translation.load_server(locale)
  end
  
  add_class_method(:i18n, :available_locales) do
    available_locales_core.select { |l| Multilingual::Interface.enabled?(l) }
  end
  
  add_class_method(:js_locale_helper, :plugin_client_files) do |locale_str|
    Dir[
      "#{Rails.root}/plugins/*/config/locales/client.#{locale_str}.yml",
      "#{Multilingual::TranslationFile::BASE_PATH}/{#{Multilingual::Translation::CLIENT_TYPES.join(',')}}.#{locale_str}.yml"
    ]
  end
  
  ### Note ###
  # The featured topic list in CategoryList is used in the /categories route:
  #   * when desktop_category_page_style includes 'featured'; and / or
  #   * on mobile
  # It does not use TopicQuery and does not have access to the current_user.
  # The modifications to trim_results below ensures non-content-language topics do not appear, but
  # as it is filtering a limited list of 100 featured topics, may be empty when
  # relevant topics in the user's content-language remain in the category.
  ###
  
  CategoryList.send(:alias_method, :trim_results_core, :trim_results)
  
  add_to_class(:category_list, :trim_results) do
    @categories.each do |c|
      next if c.displayable_topics.blank?
      c.displayable_topics = c.displayable_topics.select do |topic|
        Multilingual::ContentTag.filter(topic).any?
      end
    end
    trim_results_core
  end
  
  add_to_serializer(:topic_view, :content_language_tags) do
    Multilingual::ContentTag.filter(topic.tags).map(&:name)
  end
  
  add_to_serializer(:topic_list_item, :content_language_tags) do
    Multilingual::ContentTag.filter(topic.tags).map(&:name)
  end
  
  ## This is necessary due to the workaround for jquery ajax added in multilingual-initializer
  on(:user_updated) do |user|
    if user.custom_fields['content_languages'].blank?
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
  
  DiscourseTagging.singleton_class.send(:alias_method, :tag_topic_by_names_core, :tag_topic_by_names)
  
  add_class_method(:discourse_tagging, :tag_topic_by_names) do |topic, guardian, tag_names_arg, append: false|
    return false unless validate_require_language_tag(guardian, topic, tag_names_arg)
    tag_topic_by_names_core(topic, guardian, tag_names_arg, append: append)
  end
  
  DiscourseTagging.singleton_class.send(:alias_method, :filter_allowed_tags_core, :filter_allowed_tags)
  
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
  
  SiteCategorySerializer.send(:alias_method, :name_core, :name)
  
  add_to_serializer(:site_category, :name) do
    puts "NAMES: #{Multilingual::Translation.category_names[slug]}; #{name_core}"
    Multilingual::Translation.category_names[slug] || name_core
  end
  
  add_to_serializer(:site_category, :name_translated) do
    Multilingual::Translation.category_names[slug].present?
  end
  
  BasicCategorySerializer.send(:alias_method, :name_core, :name)
  
  add_to_serializer(:basic_category, :name) do
    Multilingual::Translation.category_names[slug] || name_core
  end
  
  add_to_serializer(:basic_category, :name_translated) do
    Multilingual::Translation.category_names[slug].present?
  end
  
  Multilingual::Language.setup!
  Multilingual::Translation.setup!
end