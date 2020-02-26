module ExtraLocalesControllerMultilingualClassExtension
  def current_locale
    I18n.locale.to_s
  end
  
  def custom_language?
    Multilingual::CustomLanguage.is_custom?(current_locale)
  end
  
  def bundle_js(bundle)
    if bundle === "custom-language" && custom_language?
      JsLocaleHelper.output_locale(current_locale)
    elsif bundle === 'tags'
      JsLocaleHelper.output_locale_tags(current_locale)
    else
      super(bundle)
    end
  end
end