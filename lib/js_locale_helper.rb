module JsLocaleHelperMultilingualExtension  
  def plugin_client_files(locale_str)
    Dir[
      "#{Rails.root}/plugins/*/config/locales/client.#{locale_str}.yml",
      "#{Multilingual::TranslationFile::BASE_PATH}/{#{Multilingual::Translation::CLIENT_TYPES.join(',')}}.#{locale_str}.yml"
    ]
  end
end

module JsLocaleHelper
  singleton_class.prepend JsLocaleHelperMultilingualExtension if SiteSetting.multilingual_enabled
end