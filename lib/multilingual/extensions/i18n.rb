module I18nMultilingualExtension
  def ensure_all_loaded!
    super
    Multilingual::Translation.load_extra(locale)
  end
  
  def available_locales
    super.select { |l| Multilingual::InterfaceLanguage.enabled?(l) }
  end
  
  def locale_available?(locale)
    Multilingual::InterfaceLanguage.enabled?(locale) || super(locale)
  end
end