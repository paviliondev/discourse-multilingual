# frozen_string_literal: true
class Multilingual::InterfaceLanguage
  include ActiveModel::Serialization

  attr_reader :locale, :name

  KEY ||= 'interface_language'.freeze

  def initialize(locale, name)
    @locale = locale
    @name = name
  end

  def self.excluded?(locale)
    Multilingual::LanguageExclusion.get(KEY, locale)
  end

  def self.supported?(locale)
    self.all.include?(locale.to_s)
  end

  def self.enabled?(locale)
    Multilingual::Language.exists?(locale) && supported?(locale) && !excluded?(locale)
  end

  def self.all
    Multilingual::Cache.wrap(KEY) { ::LocaleSiteSetting.supported_locales }
  end

  def self.list
    self.all.select { |locale| self.enabled?(locale) }
      .map { |locale|self.new(locale, Multilingual::Language.all[locale]['nativeName']) }
      .sort_by(&:locale)
  end
end
