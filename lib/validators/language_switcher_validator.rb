# frozen_string_literal: true

class LanguageSwitcherValidator
  
  def initialize(opts = {})
    @opts = opts
  end

  def valid_value?(val)
    val == "f" || (val == "t" && SiteSetting.allow_user_locale)
  end

  def error_message
    if !SiteSetting.multilingual_enabled
      I18n.t("site_settings.errors.multilingual_disabled")
    elsif !SiteSetting.allow_user_locale
      I18n.t("site_settings.errors.multilingual_allow_user_locale_disabled")
    end
  end
end
