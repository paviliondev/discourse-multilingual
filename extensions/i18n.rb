module I18nMultilingualExtension  
  def available_locales
    super.select { |l| Multilingual::InterfaceLanguage.enabled?(l) }
  end
  
  def locale_available?(locale)
    Multilingual::InterfaceLanguage.supported?(locale) || super(locale)
  end
end