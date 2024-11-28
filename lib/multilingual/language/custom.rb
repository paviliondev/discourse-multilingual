# frozen_string_literal: true
class Multilingual::CustomLanguage
  KEY = "custom_language".freeze
  ATTRS = %i[name nativeName]

  def self.all
    Multilingual::Cache.wrap(KEY) do
      result = {}

      PluginStoreRow
        .where(
          "
        plugin_name = '#{Multilingual::PLUGIN_NAME}' AND
        key LIKE '#{Multilingual::CustomLanguage::KEY}_%'
      ",
        )
        .each do |record|
          begin
            locale = record.key.split("#{Multilingual::CustomLanguage::KEY}_").last
            result[locale] = JSON.parse(record.value)
          rescue JSON::ParserError => e
            puts e.message
          end
        end

      result
    end
  end

  def self.create(locale, opts = {})
    Multilingual::Language.before_change if opts[:run_hooks]

    if PluginStore.set(
         Multilingual::PLUGIN_NAME,
         "#{KEY}_#{locale}",
         opts.with_indifferent_access.slice(*ATTRS),
       )
      after_create([locale]) if opts[:run_hooks]
      true
    end
  end

  def self.destroy(locale, opts = {})
    Multilingual::Language.before_change if opts[:run_hooks]

    Multilingual::LanguageExclusion.set(locale, Multilingual::InterfaceLanguage::KEY, enabled: true)
    Multilingual::LanguageExclusion.set(locale, Multilingual::ContentLanguage::KEY, enabled: true)

    if PluginStore.remove(Multilingual::PLUGIN_NAME, "#{KEY}_#{locale}")
      after_destroy([locale]) if opts[:run_hooks]
      true
    end
  end

  def self.after_create(created)
    Multilingual::ContentTag.bulk_update(created, "enable")
    Multilingual::Language.after_change(created)
  end

  def self.after_destroy(destroyed)
    Multilingual::ContentTag.bulk_destroy(destroyed)
    Multilingual::Language.after_change(destroyed)
  end

  def self.is_custom?(locale)
    all.keys.include?(locale.to_s)
  end

  def self.bulk_create(languages = {})
    created = []

    Multilingual::Language.before_change

    PluginStoreRow.transaction do
      languages.each { |k, v| created.push(k) if create(k, v) }

      after_create(created)
    end

    created
  end

  def self.bulk_destroy(locales)
    destroyed = []

    Multilingual::Language.before_change

    PluginStoreRow.transaction do
      [*locales].each { |c| destroyed.push(c) if destroy(c) }

      after_destroy(destroyed)
    end

    destroyed
  end
end
