# frozen_string_literal: true
class Multilingual::CustomTranslation < ActiveRecord::Base
  self.table_name = 'custom_translations'

  PATH ||= "#{Multilingual::PLUGIN_PATH}/config/translations".freeze
  KEY ||= 'file'.freeze

  validates :file_name, :code, :file_type, :file_ext, :translation_data, presence: true
  serialize :translation_data
  before_save :save_file
  after_save :after_save

  #TODO confirm what needs to be added to cache and add test
  #TODO implement
  #TODO iterate model on initialise to re-instantiate files and cache

  def exists?
    self.class.all.map(&:code).include?(self.code)
  end

  def open
    YAML.safe_load(File.open(path)) if exists?
  end

  def save_file
    result = Hash.new

    processed = process(self.translation_data)
    result[:error] = processed[:error] if processed[:error]

    return result if result[:error]

    unless self.file_type == "server"
      File.open(path, 'w') { |f| f.write file_name.to_yaml }

      config = Rails.application.config

      config.i18n.load_path += Dir[path]

      result = restore_file(processed[:translations])
    else
      result = processed[:translations][self.code]
    end

    result
  end

  def restore_file(processed_translations)
    file = format(processed_translations)
    File.open(path, 'w') { |f| f.write file.to_yaml }

    result = processed_translations
  end

  def interface_file
    self.file_type === "server" || self.file_type === "client"
  end

  def remove
    if exists?
      File.delete(path) if File.exist?(path)
      after_remove
    end
  end

  def after_save
    add_locale_to_cache
    Multilingual::TranslationLocale.register(self) if interface_file
    if self.file_type == "client"
      after_all(reload_i18n: true, locale: self.code, action: :save)
    end
  end

  def after_remove
    Multilingual::TranslationLocale.deregister(self) if interface_file
    after_all(reload_i18n: true, locale: self.code, action: :remove)
  end

  def after_all(opts = {})
    Multilingual::Cache.refresh!(opts)
    Multilingual::Cache.refresh_clients(self.code)
  end

  def path
    PATH + "/#{filename}"
  end

  def filename
    "#{self.file_type.to_s}.#{self.code.to_s}.yml"
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

    translations.each do |key, translation|

      if self.file_type === :tag && SiteSetting.multilingual_tag_translations_enforce_format
        translations[key] = DiscourseTagging.clean_tag(translation)
      end
      if self.file_type === "server"
        I18n.backend.store_translations(self.code.to_sym, translation)
      end
    end

    result[:translations] = translations

    result
  end

  ## Use this to apply any necessary formatting
  def format(content)
    file = Hash.new
    file = content
    file
  end

  def add_locale_to_cache
    existing_locales = I18n.config.available_locales
    new_locales      = existing_locales.push(self.code.to_sym)
    I18n.config.available_locales = new_locales
  end

  def self.by_type(types)
    all.select { |f| [*types].map(&:to_sym).include?(f[:file_type].to_sym) }
  end

  def self.filenames
    if Dir.exist?(PATH)
      Dir.entries(PATH)
    else
      load
      filenames
    end
  end

  def self.load
    Dir.mkdir(PATH) unless Dir.exist?(PATH)
  end
end
