module I18nMultilingualExtension
  def ensure_all_loaded!
    super
    Multilingual::Translation.load_custom_types(locale)
  end
  
  def available_locales
    super.select { |l| Multilingual::InterfaceLanguage.enabled?(l) }
  end
  
  def locale_available?(locale)
    Multilingual::InterfaceLanguage.supported?(locale) || super(locale)
  end
end