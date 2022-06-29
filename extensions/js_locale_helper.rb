# frozen_string_literal: true
module JsLocaleHelperMultilingualExtension
  def plugin_client_files(locale_str)
    files = super(locale_str)
    if SiteSetting.multilingual_enabled
      files += Dir["#{Multilingual::CustomTranslation::PATH}/client.#{locale_str}.yml"]
    end
    files
  end
end
