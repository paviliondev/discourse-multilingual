module I18nMultilingualExtension  
  def available_locales
    if SiteSetting.multilingual_enabled
      super.select { |l| Multilingual::InterfaceLanguage.enabled?(l) }
    else
      super
    end
  end
  
  def locale_available?(locale)
    if SiteSetting.multilingual_enabled
      Multilingual::InterfaceLanguage.supported?(locale) || super(locale)
    else
      super
    end
  end
end