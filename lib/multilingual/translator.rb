# frozen_string_literal: true
class Multilingual::Translator
  def self.lang_field
    "DiscourseTranslator".constantize::DETECTED_LANG_CUSTOM_FIELD
  end

  def self.enabled?
    SiteSetting.respond_to?(:translator_enabled) && SiteSetting.translator_enabled
  end

  def self.content_tag_sync_allowed?
    Multilingual::ContentLanguage.enabled && enabled?
  end

  def self.content_tag_sync_enabled
    content_tag_sync_allowed? && SiteSetting.multilingual_translator_content_tag_sync
  end
end
