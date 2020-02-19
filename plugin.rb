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

after_initialize do
  %w[
    ../lib/multilingual/engine.rb
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
  
  I18n.load_path = Dir[
    "#{Rails.root}/plugins/*/config/locales/*.yml",
    "#{Multilingual::TranslationFile::PATH}/{client,server}.*.yml"
  ]
  
  if SiteSetting.multilingual_enabled
    Multilingual::Cache.setup
    Multilingual::Translation.setup
    Multilingual::Language.setup
  end
  
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
  add_to_serializer(:site, :interface_languages) { serialize_languages(object.interface_languages) }
  
  add_class_method(:locale_site_setting, :valid_value?) do |val|
    supported_locales.include?(val) && Multilingual::InterfaceLanguage.enabled?(val)
  end
  
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
  
  add_class_method(:js_locale_helper, :plugin_client_files) do |locale_str|
    Dir[
      "#{Rails.root}/plugins/*/config/locales/client.#{locale_str}.yml",
      "#{Multilingual::TranslationFile::PATH}/{client,tag}.#{locale_str}.yml"
    ]
  end
  
  add_to_class(:application_helper, :preload_script) do |script|
    return if custom_locale? && script === "locales/#{I18n.locale}"
    path = script_asset_path(script)
    preload_script_url(path)
  end
  
  add_to_class(:application_helper, :current_locale) { I18n.locale.to_s }
  add_to_class(:application_helper, :custom_locale?) { Multilingual::CustomLanguage.is_custom?(current_locale) }
  add_to_class(:application_helper, :preload_i18n) { preload_script("locales/i18n") if custom_locale? }
  add_to_class(:application_helper, :preload_custom_locale) { preload_script_url(ExtraLocalesController.url('custom-language')) if custom_locale? }
  add_to_class(:application_helper, :asset_path) { |url| ActionController::Base.helpers.asset_path(url) }
  
  class ::CustomLocaleLoader
    include ::ApplicationHelper
  end
  
  register_html_builder('server:before-script-load') { CustomLocaleLoader.new.preload_i18n }
  register_html_builder('server:before-script-load') { CustomLocaleLoader.new.preload_custom_locale }
  
  add_to_class(:application_controller, :guest_locale) do
    cookies[:discourse_guest_locale] || params[:guest_locale]
  end
  
  add_to_class(:application_controller, :set_locale) do
    if !current_user
      if SiteSetting.multilingual_language_switcher != "off" && guest_locale
        locale = guest_locale
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
    if user.custom_fields['content_languages'].blank?
      user.custom_fields['content_languages'] = []
      user.save_custom_fields(true)
    end
  end
  
  add_to_serializer(:topic_view, :content_language_tags) do
    Multilingual::ContentTag.filter(topic.tags).map(&:name)
  end
  
  add_to_serializer(:topic_list_item, :content_language_tags) do
    Multilingual::ContentTag.filter(topic.tags).map(&:name)
  end
  
  add_to_class(:topic, :content_languages) do
    if custom_fields['content_languages']
      [*custom_fields['content_languages']]
    else
      []
    end
  end
  
  on(:before_create_topic) do |topic, creator|
    content_language_tags = [*creator.opts[:content_language_tags]]
        
    if !DiscourseTagging.validate_require_language_tag(
        creator.guardian,
        topic,
        content_language_tags
      )
      creator.rollback_from_errors!(topic)
    end
        
    Multilingual::ContentTag.add_to_topic(topic, content_language_tags)
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
      
  add_to_serializer(:basic_category, :name) do
    Multilingual::Translation.category_names[slug] ||
    (object.uncategorized? ? 
    I18n.t('uncategorized_category_name', locale: SiteSetting.default_locale) :
    object.name)
  end
  
  add_to_serializer(:basic_category, :name_translated) do
    Multilingual::Translation.category_names[slug].present?
  end
  
  add_to_class(:extra_locales_controller, :valid_bundle?) do |bundle|
    bundle == ExtraLocalesController::OVERRIDES_BUNDLE ||
    (bundle =~ /^(admin|wizard)$/ && current_user&.staff?) ||
    (bundle === 'custom-language' && Multilingual::CustomLanguage.is_custom?(I18n.locale.to_s))
  end
  
  ## Extensions
  
  %w[
    ../lib/multilingual/extensions/category_list.rb
    ../lib/multilingual/extensions/discourse_tagging.rb
    ../lib/multilingual/extensions/extra_locales_controller.rb
    ../lib/multilingual/extensions/i18n.rb
    ../lib/multilingual/extensions/topic_serializer.rb
  ].each do |path|
    load File.expand_path(path, __FILE__)
  end
  
  if SiteSetting.multilingual_enabled
    module ::I18n
      class << self
        prepend I18nMultilingualExtension
      end
    end
    
    class ::ExtraLocalesController      
      class << self
        prepend ExtraLocalesControllerMultilingualClassExtension
      end
    end
    
    class ::TopicViewSerializer
      prepend TopicSerializerMultilingualExtension 
    end
    
    class ::TopicListItemSerializer
      prepend TopicSerializerMultilingualExtension
    end
    
    module ::DiscourseTagging
      class << self
        prepend DiscourseTaggingMultilingualExtension
      end
    end
    
    class ::CategoryList
      prepend CategoryListMultilingualExtension
    end
  end
  
  ## Hooks
  
  if SiteSetting.multilingual_enabled
    TopicQuery.add_custom_filter(:content_language) do |result, query|
      if query.user && query.user.content_languages.any?
        result.joins(:tags).where("lower(tags.name) in (?)", query.user.content_languages)
      else
        result
      end
    end
    
    tags_cb = ::PostRevisor.tracked_topic_fields[:tags]
    
    ::PostRevisor.tracked_topic_fields[:tags] = lambda do |tc, tags|
      content_languages = tc.topic.content_languages
      combined = (tags + content_languages).uniq
      tc.check_result(DiscourseTagging.validate_require_language_tag(tc.guardian, tc.topic, combined))
      tags_cb.call(tc, combined)
    end
    
    ::PostRevisor.track_topic_field(:content_language_tags) do |tc, content_language_tags|
      content_language_tags = [*content_language_tags]
      tc.check_result(DiscourseTagging.validate_require_language_tag(tc.guardian, tc.topic, content_language_tags))
      tc.check_result(Multilingual::ContentTag.add_to_topic(tc.topic, content_language_tags))
    end
  end
end