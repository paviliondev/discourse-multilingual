module I18nMultilingualExtension
  def ensure_all_loaded!
    super
    Multilingual::Translation.reset_server!
    Multilingual::Translation.load_server(locale)
  end
end

module I18n
  singleton_class.prepend I18nMultilingualExtension if SiteSetting.multilingual_enabled
end