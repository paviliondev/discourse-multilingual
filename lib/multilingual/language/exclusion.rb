# frozen_string_literal: true
class Multilingual::LanguageExclusion
  KEY ||= "language_exclusion".freeze

  def self.all
    Multilingual::Cache.wrap(KEY) { all_uncached }
  end

  def self.all_uncached
    PluginStore.get(Multilingual::PLUGIN_NAME, KEY) || {}
  end

  def self.list(type)
    all[type] || []
  end

  def self.get(type, locale)
    list(type).include?(locale.to_s)
  end

  def self.set(locale, type, params = {})
    locale = locale.to_s
    enabled = ActiveModel::Type::Boolean.new.cast(params[:enabled])
    exclusions = all_uncached[type] || []

    return if enabled && exclusions.blank?

    if enabled
      exclusions.delete(locale)
    else
      exclusions.push(locale) unless (exclusions.include?(locale) || locale == 'en')
    end

    data = all_uncached
    data[type] = exclusions

    PluginStore.set(Multilingual::PLUGIN_NAME, KEY, data)
  end
end
