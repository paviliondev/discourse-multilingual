# name: discourse-multilingual
# about: Features to support multilingual forums
# version: 0.1.0
# url: https://github.com/paviliondev/discourse-multilingual
# authors: Angus McLeod

enabled_site_setting :multilingual_enabled

register_asset 'stylesheets/common/multilingual.scss'
register_asset 'stylesheets/mobile/multilingual.scss', :mobile

if respond_to?(:register_svg_icon)
  register_svg_icon "language"
  register_svg_icon "translate"
  register_svg_icon "save"
end

%w[
  ../lib/validators/content_languages_validator.rb
  ../lib/validators/language_switcher_validator.rb
  ../lib/validators/translator_content_tag_validator.rb
].each do |path|
  load File.expand_path(path, __FILE__)
end

after_initialize do
  %w[
    ../lib/multilingual/multilingual.rb
    ../lib/multilingual/cache.rb
    ../lib/multilingual/language/content_tag.rb
    ../lib/multilingual/language/exclusion.rb
    ../lib/multilingual/language/custom.rb
    ../lib/multilingual/language/content.rb
    ../lib/multilingual/language/interface.rb
    ../lib/multilingual/language.rb
    ../lib/multilingual/translation/file.rb
    ../lib/multilingual/translation/locale.rb
    ../lib/multilingual/translation.rb
    ../lib/multilingual/translator.rb
    ../lib/multilingual/locale_loader.rb
    ../jobs/update_content_language_tags.rb
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

  Multilingual.setup if SiteSetting.multilingual_enabled
  
  ## Core changes and additions
  # - Plugin api: changes via the server-side plugin api
  # - Extensions: changes not possible via the plugin api
  # - Hooks: additions via class hooks
  ##
  
  ## Plugin api
  
  add_to_class(:site, :interface_languages) { Multilingual::InterfaceLanguage.list }
  add_to_class(:site, :content_languages) { Multilingual::ContentLanguage.list }
  
  add_to_serializer(:site, :serialize_languages) do |languages = []|
    params = { each_serializer: Multilingual::BasicLanguageSerializer, root: false }
    ActiveModel::ArraySerializer.new(languages, params).as_json
  end
  
  add_to_serializer(:site, :content_languages) { serialize_languages(object.content_languages) }
  add_to_serializer(:site, :include_content_languages?) { Multilingual::ContentLanguage.enabled }
  add_to_serializer(:site, :interface_languages) { serialize_languages(object.interface_languages) }

  add_class_method(:locale_site_setting, :valid_value?) { |val| Multilingual::InterfaceLanguage.supported?(val) }
  
  add_class_method(:locale_site_setting, :values) do
    @values ||= supported_locales.reduce([]) do |result, locale|
      if Multilingual::InterfaceLanguage.enabled?(locale)
        lang = Multilingual::Language.all[locale] || Multilingual::Language.all[locale.split("_")[0]]
        result.push(
          name: lang ? lang['nativeName'] : locale,
          value: locale
        )
      end
      result
    end
  end
  
  add_class_method(:js_locale_helper, :output_locale_tags) do |locale_str|
    <<~JS
      I18n.tag_translations = #{Multilingual::Translation.get("tag", locale_str).to_json};
    JS
  end
  
  register_html_builder('server:before-script-load') do
    loader = Multilingual::LocaleLoader.new
    result = ""
    
    result << loader.preload_i18n
    result << loader.preload_custom_locale if loader.custom_locale?
    result << loader.preload_tag_translations
    
    result
  end
  
  add_to_class(:application_controller, :client_locale) do
     params[:locale] || cookies[:discourse_locale]
  end
  
  add_to_class(:application_controller, :set_locale) do
    if !current_user
      if SiteSetting.multilingual_guest_language_switcher != "off" && client_locale
        locale = client_locale
      elsif SiteSetting.set_locale_from_accept_language_header
        locale = locale_from_header
      else
        locale = SiteSetting.default_locale
      end
    else
      locale = current_user.effective_locale
    end
    
    I18n.locale = locale ? locale : SiteSettings::DefaultsProvider::DEFAULT_LOCALE
    I18n.ensure_all_loaded!
  end
  
  if defined? register_editable_user_custom_field
    register_editable_user_custom_field :content_languages 
    register_editable_user_custom_field content_languages: []
  end
  
  if defined? whitelist_public_user_custom_field
    whitelist_public_user_custom_field :content_languages
  end
    
  add_to_class(:user, :effective_locale) do
    if SiteSetting.allow_user_locale &&
       self.locale.present? &&
       Multilingual::InterfaceLanguage.enabled?(self.locale)
      self.locale
    else
      SiteSetting.default_locale
    end
  end
  
  add_to_serializer(:user, :locale) do
    Multilingual::InterfaceLanguage.enabled?(object.locale) ? object.locale : nil
  end
  
  on(:site_setting_changed) do |setting, old_val, new_val|
    if setting.to_sym == :multilingual_content_languages_enabled && 
       ActiveModel::Type::Boolean.new.cast(new_val)
      Multilingual::ContentTag.enqueue_update_all
    end
  end
  
  add_to_class(:user, :content_languages) do
    content_languages = self.custom_fields['content_languages'] || []
    [*content_languages].select{ |l| Multilingual::ContentLanguage.enabled?(l) }
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
  
  ## This is necessary due to the workaround for jquery ajax added in multilingual-initializer
  on(:user_updated) do |user|
    if Multilingual::ContentLanguage.enabled && user.custom_fields['content_languages'].blank?
      user.custom_fields['content_languages'] = []
      user.save_custom_fields(true)
    end
  end
  
  add_to_serializer(:topic_view, :content_language_tags) { Multilingual::ContentTag.filter(topic.tags).map(&:name) }
  add_to_serializer(:topic_view, :include_content_language_tags?) { Multilingual::ContentLanguage.enabled }
  add_to_serializer(:topic_list_item, :content_language_tags) { Multilingual::ContentTag.filter(topic.tags).map(&:name) }
  add_to_serializer(:topic_list_item, :include_content_language_tags?) { Multilingual::ContentLanguage.enabled }
  
  add_to_class(:topic, :content_languages) do
    if custom_fields['content_languages']
      [*custom_fields['content_languages']]
    else
      []
    end
  end
  
  on(:before_create_topic) do |topic, creator|
    if Multilingual::ContentLanguage.enabled
      content_language_tags = [*creator.opts[:content_language_tags]]

      if !DiscourseTagging.validate_require_language_tag(
          creator.guardian,
          topic,
          content_language_tags
        )
        creator.rollback_from_errors!(topic)
      end
          
      Multilingual::ContentTag.update_topic(topic, content_language_tags)
    end
  end
  
  add_to_class(:guardian, :topic_requires_language_tag?) do |topic|
    !topic.private_message? &&
    Multilingual::ContentLanguage.enabled &&
    (SiteSetting.multilingual_require_content_language_tag === 'yes' ||
    (!is_staff? && SiteSetting.multilingual_require_content_language_tag === 'non-staff'))
  end
  
  add_class_method(:discourse_tagging, :validate_require_language_tag) do |guardian, topic, tag_names|
    if guardian.topic_requires_language_tag?(topic) && (tag_names.blank? || 
       !Tag.where(name: tag_names).where("id IN (
          #{DiscourseTagging::TAG_GROUP_TAG_IDS_SQL}
          AND tg.name = '#{Multilingual::ContentTag::GROUP}'
        )").exists?)

      topic.errors.add(:base,
        I18n.t(
         "tags.required_tags_from_group",
         count: 1,
         tag_group_name: Multilingual::ContentTag::GROUP
        )
      )
      
      false
    else
      true
    end
  end
  
  add_to_serializer(:basic_category, :name_translations) do
    Multilingual::Translation.get("category_name", object.slug_path)
  end
  
  add_to_serializer(:basic_category, :include_name_translations?) { name_translations.present? }
  
  add_to_class(:tag_groups_controller, :destroy_content_tags) do
    guardian.is_admin?
    Multilingual::ContentTag.destroy_all
    render json: success_json
  end
  
  add_to_class(:tag_groups_controller, :update_content_tags) do
    guardian.is_admin?
    Multilingual::ContentTag.update_all
    render json: success_json
  end
  
  add_to_serializer(:tag_group, :content_language_group) do
    content_language_group_enabled || content_language_group_disabled
  end
  
  add_to_serializer(:tag_group, :content_language_group_enabled) do
    object.id == Multilingual::ContentTag.enabled_group.id
  end
  
  add_to_serializer(:tag_group, :content_language_group_disabled) do
    object.id == Multilingual::ContentTag.disabled_group.id
  end
  
  add_to_serializer(:tag_group, :name) do
    content_language_group ?
    I18n.t("multilingual.content_tag_group_name#{content_language_group_disabled ? "_disabled" : ""}") :
    object.name
  end
  
  ## Extensions
  
  %w[
    ../extensions/category_list.rb
    ../extensions/discourse_tagging.rb
    ../extensions/extra_locales_controller.rb
    ../extensions/i18n.rb
    ../extensions/js_locale_helper.rb
    ../extensions/post.rb
    ../extensions/tag_group.rb
    ../extensions/topic_serializer.rb
  ].each do |path|
    load File.expand_path(path, __FILE__)
  end
  
  if SiteSetting.multilingual_enabled
    module ::I18n
      class << self
        prepend I18nMultilingualExtension
      end
    end
    
    module ::JsLocaleHelper
      class << self
        prepend JsLocaleHelperMultilingualExtension
      end
    end
    
    class ::ExtraLocalesController      
      class << self
        prepend ExtraLocalesControllerMultilingualClassExtension
      end
      
      prepend ExtraLocalesControllerMultilingualExtension
    end
    
    class ::TopicViewSerializer
      prepend TopicSerializerMultilingualExtension 
    end
    
    class ::TopicListItemSerializer
      prepend TopicSerializerMultilingualExtension
    end
    
    class ::TagGroup
      class << self
        prepend TagGroupMultilingualExtension
      end
    end
    
    module ::DiscourseTagging
      class << self
        prepend DiscourseTaggingMultilingualExtension
      end
    end
    
    class ::CategoryList
      prepend CategoryListMultilingualExtension
    end
    
    class ::Post
      prepend MultilingualTranslatorPostExtension
    end
  end
  
  ## Hooks
  
  if SiteSetting.multilingual_enabled
    TopicQuery.add_custom_filter(:content_languages) do |result, query|
      if Multilingual::ContentLanguage.enabled
        content_languages = query.user ?
                            query.user.content_languages :
                            [*query.options[:content_languages]]
            
        if content_languages.present? && content_languages.any?
          result = result.joins(:tags).where("lower(tags.name) in (?)", content_languages)
        end
      end
      
      result
    end
    
    tags_cb = ::PostRevisor.tracked_topic_fields[:tags]
    
    ::PostRevisor.tracked_topic_fields[:tags] = lambda do |tc, tags|
      if Multilingual::ContentLanguage.enabled
        content_languages = tc.topic.content_languages
        combined = (tags + content_languages).uniq
        tc.check_result(DiscourseTagging.validate_require_language_tag(tc.guardian, tc.topic, combined))
        tags_cb.call(tc, combined)
      end
    end
    
    ::PostRevisor.track_topic_field(:content_language_tags) do |tc, content_language_tags|
      if Multilingual::ContentLanguage.enabled
        content_language_tags = [*content_language_tags]
        tc.check_result(DiscourseTagging.validate_require_language_tag(tc.guardian, tc.topic, content_language_tags))
        tc.check_result(Multilingual::ContentTag.update_topic(tc.topic, content_language_tags))
      end
    end
  end
end