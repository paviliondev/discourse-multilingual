# frozen_string_literal: true
class Multilingual::TranslationLocale
  def self.register(file)
    code = file.code.to_s
    type = file.type.to_s

    opts = {}
    opts["#{type}_locale_file".to_sym] = file.path

    locale_chain = code.split('_')
    opts[:fallbackLocale] = locale_chain.first if locale_chain.length === 2

    current_locale = DiscoursePluginRegistry.locales[code] || {}
    new_locale = current_locale.merge(opts)

    DiscoursePluginRegistry.register_locale(code, new_locale)
  end

  def self.deregister(file)
    DiscoursePluginRegistry.locales.delete(file.code.to_s)
  end

  def self.load
    files.each { |file| register(file) }
  end

  def self.files
    Multilingual::TranslationFile.by_type([:client, :server])
  end
end
