# frozen_string_literal: true
module ExtraLocalesControllerMultilingualClassExtension

  OVERRIDES_BUNDLE ||= 'overrides'

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

  def bundle_js_hash(bundle)
    if bundle == OVERRIDES_BUNDLE
      site = RailsMultisite::ConnectionManagement.current_db

      @by_site ||= {}
      @by_site[site] ||= {}
      @by_site[site][I18n.locale] ||= begin
        js = bundle_js(bundle)
        js.present? ? Digest::MD5.hexdigest(js) : nil
      end
    elsif bundle == "tags"
      Digest::MD5.hexdigest(bundle_js(bundle))
    else
      @bundle_js_hash ||= {}
      @bundle_js_hash["#{bundle}_#{I18n.locale}"] ||= Digest::MD5.hexdigest(bundle_js(bundle))
    end
  end
end

module ExtraLocalesControllerMultilingualExtension
  private def valid_bundle?(bundle)
    super || (
      SiteSetting.multilingual_enabled &&
      ((bundle === 'custom-language' &&
        Multilingual::CustomLanguage.is_custom?(I18n.locale.to_s)) ||
       bundle === 'tags')
    )
  end
end
