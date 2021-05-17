# frozen_string_literal: true
class Multilingual::InterfaceLanguage
  include ActiveModel::Serialization

  attr_reader :code, :name

  KEY ||= 'interface_language'.freeze

  def initialize(code, name)
    @code = code
    @name = name
  end

  def self.excluded?(code)
    Multilingual::LanguageExclusion.get(KEY, code)
  end

  def self.supported?(code)
    self.all.include?(code.to_s)
  end

  def self.enabled?(code)
    Multilingual::Language.exists?(code) && supported?(code) && !excluded?(code)
  end

  def self.all
    Multilingual::Cache.wrap(KEY) { ::LocaleSiteSetting.supported_locales }
  end

  def self.list
    self.all.select { |code| self.enabled?(code) }
      .map { |code|self.new(code, Multilingual::Language.all[code]['nativeName']) }
      .sort_by(&:code)
  end
end
