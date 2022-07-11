# frozen_string_literal: true
class Multilingual::ContentLanguage
  include ActiveModel::Serialization

  attr_reader :locale, :name

  KEY ||= 'content_language'.freeze

  def self.enabled
    SiteSetting.multilingual_enabled &&
    SiteSetting.multilingual_content_languages_enabled
  end

  def self.topic_filtering_enabled
    self.enabled &&
    SiteSetting.multilingual_content_languages_topic_filtering_enabled
  end

  def initialize(locale, name)
    @locale = locale
    @name = name
  end

  def self.excluded?(locale)
    Multilingual::LanguageExclusion.get(KEY, locale)
  end

  def self.enabled?(locale)
    Multilingual::Language.exists?(locale) &&
    !excluded?(locale) &&
    !Multilingual::ContentTag::Conflict.exists?(locale)
  end

  def self.all
    Multilingual::Cache.wrap(KEY) do
      Multilingual::Language.all.select { |k, v| !excluded?(k) }
    end
  end

  def self.list
    self.all.select { |k, v| self.enabled?(k) }
      .map { |k, v| self.new(k, v['nativeName']) }
      .sort_by(&:locale)
  end
end
