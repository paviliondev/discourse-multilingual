# frozen_string_literal: true
module ExtraLocalesControllerMultilingualClassExtension
  def current_locale
    I18n.locale.to_s
  end

  def custom_language?
    Multilingual::CustomLanguage.is_custom?(current_locale)
  end

  def bundle_js(bundle, locale:)
    if bundle === "custom-language" && custom_language?
      JsLocaleHelper.output_locale(locale)
    elsif bundle === "tags"
      JsLocaleHelper.output_locale_tags(locale)
    else
      super(bundle, locale: locale)
    end
  end

  def bundle_js_hash(bundle, locale:)
    if bundle == "tags"
      Digest::MD5.hexdigest(bundle_js(bundle, locale: locale))
    else
      super(bundle, locale: locale)
    end
  end
end

module ExtraLocalesControllerMultilingualExtension
  private def valid_bundle?(bundle)
    super ||
      (
        SiteSetting.multilingual_enabled &&
          (
            (
              bundle === "custom-language" &&
                Multilingual::CustomLanguage.is_custom?(I18n.locale.to_s)
            ) || bundle === "tags"
          )
      )
  end
end
