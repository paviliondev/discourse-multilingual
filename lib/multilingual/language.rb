# frozen_string_literal: true
class Multilingual::Language
  KEY ||= 'language'.freeze

  include ActiveModel::Serialization

  attr_accessor :locale,
                :name,
                :nativeName,
                :content_enabled,
                :content_tag_conflict,
                :interface_enabled,
                :interface_supported,
                :custom

  def initialize(locale, opts = {})

    @locale = locale.to_s

    opts = opts.with_indifferent_access
    @name = opts[:name].to_s
    @nativeName = opts[:nativeName].to_s

    @content_enabled = Multilingual::ContentLanguage.enabled?(@locale)
    @content_tag_conflict = Multilingual::ContentTag::Conflict.exists?(@locale)
    @interface_enabled = Multilingual::InterfaceLanguage.enabled?(@locale)
    @interface_supported = Multilingual::InterfaceLanguage.supported?(@locale)
    @custom = Multilingual::CustomLanguage.is_custom?(@locale)
  end

  def self.get(locales)
    [*locales].map { |locale| self.new(locale, self.all[locale]) }
  end

  def self.all
    Multilingual::Cache.wrap(KEY) { base.merge(Multilingual::CustomLanguage.all) }
  end

  ## Some regional locales (e.g. bs_BA, fa_IR, nb_NO, pl_PL, tr_TR, zh_CN]) are
  ## not directly represented in the Discourse language names list.
  def self.base
    result = ::LocaleSiteSetting.language_names

    ::LocaleSiteSetting.supported_locales.each do |locale|
      if !::LocaleSiteSetting.language_names[locale]
        parts = locale.split('_')
        primary_locale = parts.first
        region = parts.second

        if region && result[primary_locale]
          result[locale] = result.delete(primary_locale)
        end
      end
    end

    result
  end

  def self.exists?(locale)
    self.all[locale.to_s].present?
  end

  def self.list
    self.all.map { |k, v| self.new(k, v) }.sort_by(&:locale)
  end

  def self.filter(params = {})
    languages = self.list

    if params[:query].present?
      q = params[:query].downcase

      languages = languages.select do |l|
        l.locale.downcase.include?(q) ||
        l.name.downcase.include?(q)
      end
    end

    type = params[:order].present? ? params[:order].to_sym : :locale

    languages = languages.sort_by do |l|
      val = l.send(type)

      if [:locale, :name, :nativeName].include?(type)
        val
      elsif [:content_enabled, :custom].include?(type)
        (val ? 0 : 1)
      elsif type == :interface_enabled
        [ (val ? 0 : 1), (l.interface_supported ? 0 : 1) ]
      end
    end

    if params[:order].present? && !ActiveModel::Type::Boolean.new.cast(params[:ascending])
      languages = languages.reverse
    end

    languages
  end

  def self.update(language, opts = {})
    language = language.with_indifferent_access
    updated = false

    ['interface', 'content'].each do |type|
      exclusion_prop = "#{type}_enabled".to_sym
      exclusion_key = "#{type}_language"

      if language[exclusion_prop].in? ["true", "false", true, false]
        updated = Multilingual::LanguageExclusion.set(
          language[:locale],
          exclusion_key,
          enabled: language[exclusion_prop]
        )
      end
    end

    after_update([language[:locale]]) if opts[:run_hooks]

    updated
  end

  def self.after_update(updated)
    after_change(updated)
    Multilingual::ContentTag.update_all
  end

  def self.before_change
    Multilingual::Cache.state = 'changing'
  end

  def self.after_change(locales = [])
    Multilingual::Cache.refresh!(reload_i18n: true)
    Multilingual::Cache.refresh_clients(locales)
  end

  def self.bulk_update(languages)
    updated = []

    before_change

    PluginStoreRow.transaction do
      [*languages].each do |l|
        if update(l)
          updated.push(l['locale'])
        end
      end

      after_update(updated)
    end

    updated
  end

  def self.setup
    # no setup required
  end
end
