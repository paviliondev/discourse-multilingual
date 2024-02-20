# frozen_string_literal: true
class ::Multilingual::LocaleLoader
  attr_reader :controller

  delegate :request, to: :controller
  delegate :helpers, to: :controller, private: true
  delegate :asset_path, to: :helpers

  def initialize(controller)
    @controller = controller
  end

  def current_locale
    I18n.locale.to_s
  end

  def custom_locale?
    Multilingual::CustomLanguage.is_custom?(current_locale)
  end

  def preload_i18n
    helpers.preload_script("locales/i18n")
  end

  def preload_custom_locale
    helpers.preload_script_url(ExtraLocalesController.url("custom-language"))
  end

  def preload_tag_translations
    helpers.preload_script_url(ExtraLocalesController.url("tags"))
  end
end
