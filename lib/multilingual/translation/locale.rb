# frozen_string_literal: true
class Multilingual::TranslationLocale
  def self.register(file)
    locale = file.locale.to_s
    type = file.file_type.to_s

    opts = {}
    opts["#{type}_locale_file".to_sym] = file.path

    locale_chain = locale.split('_')
    opts[:fallbackLocale] = locale_chain.first if locale_chain.length === 2

    current_locale = DiscoursePluginRegistry.locales[locale] || {}
    new_locale = current_locale.merge(opts)

    DiscoursePluginRegistry.register_locale(locale, new_locale)
  end

  def self.deregister(file)
    DiscoursePluginRegistry.locales.delete(file.locale.to_s)
  end

  def self.load
    files.each { |file| register(file) }
  end

  def self.files
    Multilingual::CustomTranslation.by_type([:client, :server])
  end
end
