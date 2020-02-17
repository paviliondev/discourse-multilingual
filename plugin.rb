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

Rails.application.config.i18n.load_path += Dir["#{Rails.root}/plugins/discourse-multilingual/config/translations/{client,server}.*.yml"]

after_initialize do    
  %w[
    ../lib/multilingual/engine.rb
    ../lib/multilingual/cache.rb
    ../lib/multilingual/language/content_tag.rb
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
  
  if SiteSetting.multilingual_enabled
    Multilingual::Translation.setup
    Multilingual::Language.setup
  end
  
  
  ### Site changes
  
    
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
  
  module ::I18nMultilingualExtension
    def ensure_all_loaded!
      super
      
      Multilingual::Translation.refresh_server!
      Multilingual::Translation.load_server(locale)
    end
    
    def available_locales
      super.select { |l| Multilingual::Interface.enabled?(l) }
    end
  end
  
  module ::I18n
    class << self
      prepend I18nMultilingualExtension if SiteSetting.multilingual_enabled
    end
  end
  
  add_class_method(:locale_site_setting, :valid_value?) do |val|
    supported_locales.include?(val) && Multilingual::Interface.enabled?(val)
  end
  
  add_class_method(:locale_site_setting, :values) do
    @values ||= supported_locales.reduce([]) do |result, locale|
      if Multilingual::Interface.enabled?(locale)
        lang = Multilingual::Language.all[locale] || Multilingual::Language.all[locale.split("_")[0]]
        puts "VALUES: #{locale}; #{lang}"
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
      "#{Multilingual::TranslationFile::TRANSLATION_PATH}/{#{Multilingual::Translation::CLIENT.join(',')}}.#{locale_str}.yml"
    ]
  end
  
  module MultilingualApplicationControllerExtension
    def set_locale
      if SiteSetting.multilingual_language_switcher != "off" &&
         !current_user &&
         cookies[:discourse_guest_locale] &&
         I18n.locale_available?(cookies[:discourse_guest_locale])
        
        I18n.locale = cookies[:discourse_guest_locale]
        I18n.ensure_all_loaded!
      else
        super
      end
    end
  end
  
  class ::ApplicationController
    prepend MultilingualApplicationControllerExtension if SiteSetting.multilingual_enabled
  end
  
  ### User changes

  
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
      Multilingual::Interface.enabled?(self.locale)
      self.locale
    else
      SiteSetting.default_locale
    end
  end
  
  add_to_serializer(:user, :locale) do
    Multilingual::Interface.enabled?(object.locale) ? object.locale : nil
  end
  
  add_to_class(:user, :content_languages) do
    content_languages = self.custom_fields['content_languages'] || []
    [*content_languages].select{ |l| Multilingual::Content.enabled?(l) }
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
  
  ## This is necessary due to the workaround for jquery
  ## ajax added in multilingual-initializer
  on(:user_updated) do |user|
    if user.custom_fields['content_languages'].blank?
      user.custom_fields['content_languages'] = []
      user.save_custom_fields(true)
    end
  end
  
  
  ### Topic changes
  
  
  if SiteSetting.multilingual_enabled
    TopicQuery.add_custom_filter(:content_language) do |result, query|
      if query.user && query.user.content_languages.any?
        result.joins(:tags).where("lower(tags.name) in (?)", query.user.content_languages)
      else
        result
      end
    end
  end
  
  add_to_serializer(:topic_view, :content_language_tags) do
    Multilingual::ContentTag.filter(topic.tags).map(&:name)
  end
  
  add_to_serializer(:topic_list_item, :content_language_tags) do
    Multilingual::ContentTag.filter(topic.tags).map(&:name)
  end
  
  module TopicSerializerMultilingualExtension
    def tags
      super - content_language_tags
    end
  end
  
  class ::TopicViewSerializer
    prepend TopicSerializerMultilingualExtension if SiteSetting.multilingual_enabled
  end
  
  class ::TopicListItemSerializer
    prepend TopicSerializerMultilingualExtension if SiteSetting.multilingual_enabled
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
  
  
  if SiteSetting.multilingual_enabled
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
  
  module DiscourseTaggingMultilingualExtension
    def filter_allowed_tags(guardian, opts = {})
      result = super(guardian, opts)
      
      if opts[:for_input]
        result.select { |tag| Multilingual::ContentTag.names.exclude? tag.name }
      else
        result
      end
    end
  end
    
  module ::DiscourseTagging
    class << self
      prepend DiscourseTaggingMultilingualExtension if SiteSetting.multilingual_enabled
    end
  end
  
  
  ### Category changes
  
    
  add_to_serializer(:basic_category, :name) do
    Multilingual::Translation.category_names[slug] ||
    (object.uncategorized? ? 
    I18n.t('uncategorized_category_name', locale: SiteSetting.default_locale) :
    object.name)
  end
  
  add_to_serializer(:basic_category, :name_translated) do
    Multilingual::Translation.category_names[slug].present?
  end
  
  ## Note ##
  # The featured topic list in CategoryList is used in the /categories route:
  #   * when desktop_category_page_style includes 'featured'; and / or
  #   * on mobile
  # It does not use TopicQuery and does not have access to the current_user.
  # The modifications to trim_results below ensures non-content-language topics do not appear, but
  # as it is filtering a limited list of 100 featured topics, may be empty when
  # relevant topics in the user's content-language remain in the category.
  ##
  
  module CategoryListMultilingualExtension
    def trim_results
      if SiteSetting.multilingual_enabled
        @categories.each do |c|
          next if c.displayable_topics.blank?
          c.displayable_topics = c.displayable_topics.select do |topic|
            Multilingual::ContentTag.filter(topic).any?
          end
        end
      end
      super
    end
  end
  
  class ::CategoryList
    prepend CategoryListMultilingualExtension if SiteSetting.multilingual_enabled
  end
end