# frozen_string_literal: true
# name: discourse-multilingual
# about: Features to support multilingual forums
# version: 0.2.4
# url: https://github.com/paviliondev/discourse-multilingual
# authors: Angus McLeod, Robert Barrow
# contact_emails: development@pavilion.tech

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
    ../lib/multilingual/translation/locale.rb
    ../lib/multilingual/translation.rb
    ../lib/multilingual/translator.rb
    ../lib/multilingual/locale_loader.rb
    ../jobs/update_content_language_tags.rb
    ../config/routes.rb
    ../app/models/multilingual/custom_translation.rb
    ../app/serializers/multilingual/basic_language_serializer.rb
    ../app/serializers/multilingual/language_serializer.rb
    ../app/serializers/multilingual/custom_translation_serializer.rb
    ../app/controllers/multilingual/admin_controller.rb
    ../app/controllers/multilingual/admin_languages_controller.rb
    ../app/controllers/multilingual/admin_translations_controller.rb
    ../extensions/category_list.rb
    ../extensions/discourse_tagging.rb
    ../extensions/extra_locales_controller.rb
    ../extensions/i18n.rb
    ../extensions/js_locale_helper.rb
    ../extensions/post.rb
    ../extensions/tag_group.rb
    ../extensions/topic_serializer.rb
    ../extensions/application_controller.rb
    ../extensions/tag.rb
  ].each do |path|
    load File.expand_path(path, __FILE__)
  end

  Multilingual.setup if SiteSetting.multilingual_enabled

  ::I18n.singleton_class.prepend I18nMultilingualExtension
  ::JsLocaleHelper.singleton_class.prepend JsLocaleHelperMultilingualExtension
  ::ExtraLocalesController.singleton_class.prepend ExtraLocalesControllerMultilingualClassExtension
  ::ExtraLocalesController.prepend ExtraLocalesControllerMultilingualExtension
  ::TopicViewSerializer.prepend TopicSerializerMultilingualExtension
  ::TopicListItemSerializer.prepend TopicSerializerMultilingualExtension
  ::TagGroup.singleton_class.prepend TagGroupMultilingualExtension
  ::Tag.singleton_class.prepend TagMultilingualExtension
  ::DiscourseTagging.singleton_class.prepend DiscourseTaggingMultilingualExtension
  ::CategoryList.prepend CategoryListMultilingualExtension
  ::Post.prepend MultilingualTranslatorPostExtension
  ::ApplicationController.prepend ApplicationControllerMultilingualExtension

  register_html_builder('server:before-script-load') do |ctx|
    loader = Multilingual::LocaleLoader.new(ctx)
    result = ""
    result += loader.preload_i18n
    result += loader.preload_custom_locale if loader.custom_locale?
    result += loader.preload_tag_translations
    result
  end

  register_editable_user_custom_field :content_languages
  register_editable_user_custom_field content_languages: []
  allow_public_user_custom_field :content_languages

  add_to_class(:site, :interface_languages) { Multilingual::InterfaceLanguage.list }
  add_to_class(:site, :content_languages) { Multilingual::ContentLanguage.list }

  add_to_class(:user, :effective_locale) do
    if SiteSetting.allow_user_locale &&
       self.locale.present? &&
       Multilingual::InterfaceLanguage.enabled?(self.locale)
      self.locale
    else
      SiteSetting.default_locale
    end
  end

  add_to_class(:user, :content_languages) do
    content_languages = self.custom_fields['content_languages'] || []
    [*content_languages].select { |l| Multilingual::ContentLanguage.enabled?(l) }
  end

  add_to_class(:topic, :content_languages) do
    if custom_fields['content_languages']
      [*custom_fields['content_languages']]
    else
      []
    end
  end

  add_to_class(:guardian, :topic_requires_language_tag?) do |topic|
    !topic.private_message? &&
    Multilingual::ContentLanguage.enabled &&
    (SiteSetting.multilingual_require_content_language_tag === 'yes' ||
    (!is_staff? && SiteSetting.multilingual_require_content_language_tag === 'non-staff'))
  end

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

  add_class_method(:discourse_tagging, :validate_require_language_tag) do |guardian, topic, tag_names|
    if guardian.topic_requires_language_tag?(topic) && (tag_names.blank? ||
       !Tag.where(name: tag_names).where("id IN (
          #{DiscourseTagging::TAG_GROUP_TAG_IDS_SQL}
          AND tg.name = '#{Multilingual::ContentTag::GROUP}'
        )").exists?)

      topic.errors.add(:base, I18n.t("multilingual.content_language_tag_required"))

      false
    else
      true
    end
  end

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
      I18n.tag_translations = #{Multilingual::Translation.get("tag").slice(locale_str.to_sym).to_json};
    JS
  end

  add_to_serializer(:user, :locale) do
    Multilingual::InterfaceLanguage.enabled?(object.locale) ? object.locale : nil
  end

  add_to_serializer(:site, :serialize_languages) do |languages = []|
    ActiveModel::ArraySerializer.new(languages, each_serializer: Multilingual::BasicLanguageSerializer, root: false).as_json
  end

  add_to_serializer(:site, :content_languages) { serialize_languages(object.content_languages) }
  add_to_serializer(:site, :include_content_languages?) { Multilingual::ContentLanguage.enabled }
  add_to_serializer(:site, :interface_languages) { serialize_languages(object.interface_languages) }
  add_to_serializer(:topic_view, :content_language_tags) { Multilingual::ContentTag.filter(topic.tags).map(&:name) }
  add_to_serializer(:topic_view, :include_content_language_tags?) { Multilingual::ContentLanguage.enabled }
  add_to_serializer(:topic_list_item, :content_language_tags) { Multilingual::ContentTag.filter(topic.tags).map(&:name) }
  add_to_serializer(:topic_list_item, :include_content_language_tags?) { Multilingual::ContentLanguage.enabled }

  add_to_serializer(:current_user, :content_languages) do
    if user_content_languages = object.content_languages
      user_content_languages.map do |locale|
        Multilingual::BasicLanguageSerializer.new(
          Multilingual::Language.get(locale).first,
          root: false
        )
      end
    end
  end

  add_to_serializer(:basic_category, :slug_path, false) do
    object.slug_path
  end

  add_to_serializer(:basic_category, :name, false) do
    if object.uncategorized?
      I18n.t('uncategorized_category_name', locale: SiteSetting.default_locale)
    elsif !(scope && scope.current_user && scope.current_user.locale && object.slug_path && Multilingual::Translation.get("category_name", object.slug_path)).blank?
      Multilingual::Translation.get("category_name", object.slug_path)[scope.current_user.locale.to_sym] || object.name
    else
      object.name
    end
  end

  add_to_serializer(:basic_category, :description_text, false) do
    if object.uncategorized?
      I18n.t('category.uncategorized_description', locale: SiteSetting.default_locale)
    elsif !(scope && scope.current_user && scope.current_user.locale && object.slug_path && Multilingual::Translation.get("category_description", object.slug_path)).blank?
      Multilingual::Translation.get("category_description", object.slug_path)[scope.current_user.locale.to_sym] || object.description_text
    else
      object.description_text
    end
  end

  add_to_serializer(:basic_category, :description, false) do
    if object.uncategorized?
      I18n.t('category.uncategorized_description', locale: SiteSetting.default_locale)
    elsif !(scope && scope.current_user && scope.current_user.locale && object.slug_path && Multilingual::Translation.get("category_description", object.slug_path)).blank?
      Multilingual::Translation.get("category_description", object.slug_path)[scope.current_user.locale.to_sym] || object.description
    else
      object.description
    end
  end

  add_to_serializer(:basic_category, :description_excerpt, false) do
    if object.uncategorized?
      I18n.t('category.uncategorized_description', locale: SiteSetting.default_locale)
    elsif !(scope && scope.current_user && scope.current_user.locale && object.slug_path && Multilingual::Translation.get("category_description", object.slug_path)).blank?
      Multilingual::Translation.get("category_description", object.slug_path)[scope.current_user.locale.to_sym] || object.description_excerpt
    else
      object.description_excerpt
    end
  end

  add_to_serializer(:site, :categories, false) do
    object.categories.map do |c|
      if c[:slug] == "uncategorized"
        c[:name] = I18n.t('uncategorized_category_name', locale: SiteSetting.default_locale)
      elsif SiteSetting.multilingual_enabled && !(scope && scope.current_user && scope.current_user.locale && c[:slug_path] && Multilingual::Translation.get("category_name", c[:slug_path])).blank?
        c[:name] = Multilingual::Translation.get("category_name", c[:slug_path])[scope.current_user.locale.to_sym] || c[:name]
      end
      c.to_h
    end
  end

  add_to_serializer(:basic_category, :include_name_translations?) { name_translations.present? }

  add_to_serializer(:basic_category, :include_description_translations?) { description_translations.present? }

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

  ## This is necessary due to the workaround for jquery ajax added in multilingual-initializer
  on(:user_updated) do |user|
    if Multilingual::ContentLanguage.enabled && user.custom_fields['content_languages'].blank?
      user.custom_fields['content_languages'] = []
      user.save_custom_fields(true)
    end
  end

  on(:site_setting_changed) do |setting, old_val, new_val|
    if setting.to_sym == :multilingual_content_languages_enabled &&
       ActiveModel::Type::Boolean.new.cast(new_val)
      Multilingual::ContentTag.enqueue_update_all
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

  TopicQuery.add_custom_filter(:content_languages) do |result, query|
    if Multilingual::ContentLanguage.topic_filtering_enabled
      content_languages = query.user ?
                          query.user.content_languages :
                          [*query.options[:content_languages]]

      if content_languages.present? && content_languages.any?
        result = result.joins(:tags).where("tags.name in (?)", content_languages)
      end
    end

    result
  end

  tags_cb = ::PostRevisor.tracked_topic_fields[:tags]

  ::PostRevisor.tracked_topic_fields[:tags] = lambda do |tc, tags, fields|
    if Multilingual::ContentLanguage.enabled
      content_languages = tc.topic.content_languages
      combined = (tags + content_languages).uniq
      tc.check_result(DiscourseTagging.validate_require_language_tag(tc.guardian, tc.topic, combined))
      tags_cb.call(tc, combined)
    else
      tags_cb.call(tc, tags)
    end
  end

  ::PostRevisor.track_topic_field(:content_language_tags) do |tc, content_language_tags, fields|
    if Multilingual::ContentLanguage.enabled
      content_language_tags = [*content_language_tags]
      tc.check_result(DiscourseTagging.validate_require_language_tag(tc.guardian, tc.topic, content_language_tags))
      tc.check_result(Multilingual::ContentTag.update_topic(tc.topic, content_language_tags))
    end
  end
end
