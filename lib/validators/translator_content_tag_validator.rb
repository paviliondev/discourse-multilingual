# frozen_string_literal: true

class TranslatorContentTagValidator
  def initialize(opts = {})
    @opts = opts
  end

  def valid_value?(val)
    val == "f" || (val == "t" && Multilingual::Translator.content_tag_sync_allowed?)
  end

  def error_message
    if !SiteSetting.multilingual_enabled
      I18n.t("site_settings.errors.multilingual_disabled")
    elsif !SiteSetting.multilingual_content_languages_enabled
      I18n.t("site_settings.errors.multilingual_content_languages_disabled")
    elsif !Multilingual::Translator.enabled?
      I18n.t("site_settings.errors.multilingual_translator_disabled")
    end
  end
end
