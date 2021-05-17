# frozen_string_literal: true
module ApplicationControllerMultilingualExtension
  def with_resolved_locale(check_current_user: true)
    if guest_locale_switcher_enabled && client_locale
      I18n.ensure_all_loaded!
      I18n.with_locale(client_locale) { yield }
    else
      super
    end
  end

  def client_locale
    params[:locale] || cookies[:discourse_locale]
  end

  def guest_locale_switcher_enabled
    SiteSetting.multilingual_enabled &&
    SiteSetting.multilingual_guest_language_switcher != "off"
  end
end
