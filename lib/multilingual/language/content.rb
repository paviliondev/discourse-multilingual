# frozen_string_literal: true
class Multilingual::ContentLanguage
  include ActiveModel::Serialization

  attr_reader :code, :name

  KEY ||= 'content_language'.freeze

  def self.enabled
    SiteSetting.multilingual_enabled &&
    SiteSetting.multilingual_content_languages_enabled
  end

  def self.topic_filtering_enabled
    self.enabled &&
    SiteSetting.multilingual_content_languages_topic_filtering_enabled
  end

  def initialize(code, name)
    @code = code
    @name = name
  end

  def self.excluded?(code)
    Multilingual::LanguageExclusion.get(KEY, code)
  end

  def self.enabled?(code)
    Multilingual::Language.exists?(code) &&
    !excluded?(code) &&
    !Multilingual::ContentTag::Conflict.exists?(code)
  end

  def self.all
    Multilingual::Cache.wrap(KEY) do
      Multilingual::Language.all.select { |k, v| !excluded?(k) }
    end
  end

  def self.list
    self.all.select { |k, v| self.enabled?(k) }
      .map { |k, v| self.new(k, v['nativeName']) }
      .sort_by(&:code)
  end
end
