# frozen_string_literal: true
class ::Multilingual::LocaleLoader
  include ::ApplicationHelper

  attr_reader :ctx

  def initialize(ctx)
    @ctx = ctx
  end

  def request
    @ctx && @ctx.request ? @ctx.request : ActionDispatch::Request.new
  end

  def asset_path(url)
    ActionController::Base.helpers.asset_path(url)
  end

  def current_locale
    I18n.locale.to_s
  end

  def custom_locale?
    Multilingual::CustomLanguage.is_custom?(current_locale)
  end

  def preload_i18n
    preload_script("locales/i18n")
  end

  def preload_custom_locale
    preload_script_url(ExtraLocalesController.url('custom-language'))
  end

  def preload_tag_translations
    preload_script_url(ExtraLocalesController.url('tags'))
  end
end
