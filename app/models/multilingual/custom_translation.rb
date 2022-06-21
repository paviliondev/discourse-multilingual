# frozen_string_literal: true
class Multilingual::CustomTranslation < ActiveRecord::Base
  self.table_name = 'custom_translations'
  # include ActiveModel::Serialization

  PATH ||= "#{Multilingual::PLUGIN_PATH}/config/translations".freeze
  KEY ||= 'file'.freeze

  attr_accessor :file, :code, :file_type, :ext, :yml
  serialize :translation_data

  def initialize(args)
    super(args)

    opts = Multilingual::CustomTranslation.process_filename(args[:file])
      raise opts[:error] if opts[:error]
    self[:file] = args[:file]
    self[:code] = opts[:code]
    self[:file_type] = opts[:file_type]
    self[:ext] = opts[:ext]

    result = save_file(args[:yml])

      raise result[:error] if result[:error]
    self[:yml] = result

    begin
      self.save!
      add_locale_to_cache

      after_save
    rescue => e
      opts = failed_json.merge(errors: [e.message])
    end

    opts
  end

  def exists?
    self.class.all.map(&:code).include?(self[:code])
  end

  def open
    YAML.safe_load(File.open(path)) if exists?
  end

  def save_file(translations)
    result = Hash.new

    processed = process(translations)
    result[:error] = processed[:error] if processed[:error]

    return result if result[:error]

    file = format(processed[:translations])
    File.open(path, 'w') { |f| f.write file.to_yaml }

    result = processed[:translations]
  end

  def interface_file
    @file_type === :server || @file_type === :client
  end

  def remove
    if exists?
      File.delete(path) if File.exist?(path)
      after_remove
    end
  end

  def after_save
    Multilingual::TranslationLocale.register(self) #if interface_file
    after_all(reload_i18n: true, locale: self[:code], action: :save)
  end

  def after_remove
    Multilingual::TranslationLocale.deregister(self) if interface_file
    after_all(reload_i18n: true, locale: self[:code], action: :remove)
  end

  def after_all(opts = {})
    Multilingual::Cache.refresh!(opts)
    Multilingual::Cache.refresh_clients(self[:code])
  end

  def path
    PATH + "/#{filename}"
  end

  def filename
    "#{self[:file_type].to_s}.#{self[:code].to_s}.yml"
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

      if self[:file_type] === :client &&
        (translations.values.first.keys + ['js', 'admin_js', 'wizard_js']).uniq.length != 3

        result[:error] = "file format error"
      end
    end

    return result if result[:error]

    translations.each do |key, translation|

      if self[:file_type] === :tag && SiteSetting.multilingual_tag_translations_enforce_format
        translations[key] = DiscourseTagging.clean_tag(translation)
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

  # def self.all
  #   Multilingual::Cache.wrap(KEY) do
  #     filenames.reduce([]) do |result, filename|
  #       byebug
  #       opts = process_filename(filename)
  #       result.push(Multilingual::CustomTranslation.new(opts)) if !opts[:error]
  #       result
  #     end
  #   end
  # end

  def add_locale_to_cache
    I18n.available_locales = I18n.available_locales.push(self[:code].to_sym)
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

  def self.process_filename(filename)
    result = Hash.new
    parts = filename.split('.')
    result = {
      file_type: parts[0],
      code: parts[1],
      ext: parts[2]
    }

    if !Multilingual::Translation.validate_type(result[:file_type])
      result[:error] = 'invalid type'
    end

    if result[:ext] != 'yml'
      result[:error] = "incorrect format"
    end

    result
  end

  def self.load
    Dir.mkdir(PATH) unless Dir.exist?(PATH)
  end
end
