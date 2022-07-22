# frozen_string_literal: true
class Multilingual::CustomTranslation < ActiveRecord::Base
  self.table_name = 'custom_translations'

  PATH ||= "#{Multilingual::PLUGIN_PATH}/config/translations".freeze
  KEY ||= 'file'.freeze

  validates :file_name, :locale, :file_type, :file_ext, :translation_data, presence: true
  serialize :translation_data
  before_save :process_file
  after_save :after_save

  def exists?
    self.class.all.map(&:locale).include?(self.locale)
  end

  def process_file
    result = Hash.new

    processed = process(self.translation_data)
    result[:error] = processed[:error] if processed[:error]

    return result if result[:error]

    result = processed[:translations][self.locale]
  end

  def interface_file
    self.file_type === "server" || self.file_type === "client"
  end

  def after_save
    add_locale
    Discourse.cache.delete("discourse-multilingual_translation_#{self.file_type}")
    Multilingual::Cache.refresh_clients([self.locale])
  end

  def remove
    if exists?
      if interface_file
        process_data(self.translation_data, true)
      end
      after_remove
    end
  end

  def after_remove
    self.destroy!
    Discourse.cache.delete("discourse-multilingual_translation_#{self.file_type}")
    Multilingual::Cache.refresh_clients([self.locale])
  end

  def process(translations)
    result = Hash.new

    if interface_file
      if translations.keys.length != 1
        result[:error] = "file format error"
      end

      if Multilingual::Language.all[translations.keys.first].blank?
        result[:error] = "language not supported"
      end

      if self.file_type === :client &&
        (translations.values.first.keys + ['js', 'admin_js', 'wizard_js']).uniq.length != 3

        result[:error] = "file format error"
      end
    end

    return result if result[:error]

    process_data(translations)

    result[:translations] = translations

    result
  end

  def process_data(translations, unload = false)
    translations.each do |k, translation|
      if self.file_type === :tag && SiteSetting.multilingual_tag_translations_enforce_format
        translations[k] = DiscourseTagging.clean_tag(translation)
      end
      if interface_file
        translation.each do |key, value|
          if value.is_a?(Hash)
            key_values = dot_it(value, key)
            key_values.each do |dotted_key, dotted_value|
              if !unload
                TranslationOverride.create!(locale: self.locale, translation_key: dotted_key, value: dotted_value)
              else
                override = TranslationOverride.find_by(locale: self.locale, translation_key: dotted_key, value: dotted_value)
                override.destroy! if override
              end
            end
          else
            if !unload
              TranslationOverride.create!(locale: self.locale, translation_key: key, value: value)
            else
              override = TranslationOverride.find_by(locale: self.locale, translation_key: key, value: value)
              override.destroy! if override
            end
          end
        end
        TranslationOverride.reload_all_overrides!
      end
    end
  end

  def dot_it(object, prefix = nil)
    if object.is_a? Hash
      object.map do |key, value|
        if prefix
          dot_it value, "#{prefix}.#{key}"
        else
          dot_it value, "#{key}"
        end
      end.reduce(&:merge)
    else
      { prefix => object }
    end
  end

  ## Use this to apply any necessary formatting
  def format(content)
    file = Hash.new
    file = content
    file
  end

  def add_locale
    existing_locales = I18n.config.available_locales
    new_locales      = existing_locales.push(self.locale.to_sym)
    I18n.config.available_locales = new_locales
  end

  def self.by_type(types)
    all.select { |f| [*types].map(&:to_sym).include?(f[:file_type].to_sym) }
  end
end
