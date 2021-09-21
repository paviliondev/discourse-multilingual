# frozen_string_literal: true
class Multilingual::Language
  KEY ||= 'language'.freeze

  include ActiveModel::Serialization

  attr_accessor :code,
                :name,
                :nativeName,
                :content_enabled,
                :content_tag_conflict,
                :interface_enabled,
                :interface_supported,
                :custom

  def initialize(code, opts = {})
    @code = code.to_s

    opts = opts.with_indifferent_access
    @name = opts[:name].to_s
    @nativeName = opts[:nativeName].to_s

    @content_enabled = Multilingual::ContentLanguage.enabled?(@code)
    @content_tag_conflict = Multilingual::ContentTag::Conflict.exists?(@code)
    @interface_enabled = Multilingual::InterfaceLanguage.enabled?(@code)
    @interface_supported = Multilingual::InterfaceLanguage.supported?(@code)
    @custom = Multilingual::CustomLanguage.is_custom?(@code)
  end

  def self.get(codes)
    [*codes].map { |code| self.new(code, self.all[code]) }
  end

  def self.all
    Multilingual::Cache.wrap(KEY) { base.merge(Multilingual::CustomLanguage.all) }
  end

  ## Some regional locales (e.g. bs_BA, fa_IR, nb_NO, pl_PL, tr_TR, zh_CN]) are
  ## not directly represented in the Discourse language names list.
  def self.base
    result = ::LocaleSiteSetting.language_names

    ::LocaleSiteSetting.supported_locales.each do |code|
      if !::LocaleSiteSetting.language_names[code]
        parts = code.split('_')
        primary_code = parts.first
        region = parts.second

        if region && result[primary_code]
          result[code] = result.delete(primary_code)
        end
      end
    end

    result
  end

  def self.exists?(code)
    self.all[code.to_s].present?
  end

  def self.list
    self.all.map { |k, v| self.new(k, v) }.sort_by(&:code)
  end

  def self.filter(params = {})
    languages = self.list

    if params[:query].present?
      q = params[:query].downcase

      languages = languages.select do |l|
        l.code.downcase.include?(q) ||
        l.name.downcase.include?(q)
      end
    end

    type = params[:order].present? ? params[:order].to_sym : :code

    languages = languages.sort_by do |l|
      val = l.send(type)

      if [:code, :name, :nativeName].include?(type)
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
          language[:code],
          exclusion_key,
          enabled: language[exclusion_prop]
        )
      end
    end

    after_update([language[:code]]) if opts[:run_hooks]

    updated
  end

  def self.after_update(updated)
    after_change(updated)
    Multilingual::ContentTag.update_all
  end

  def self.before_change
    Multilingual::Cache.state = 'changing'
  end

  def self.after_change(codes = [])
    Multilingual::Cache.refresh!(reload_i18n: true)
    Multilingual::Cache.refresh_clients(codes)
  end

  def self.bulk_update(languages)
    updated = []

    before_change

    PluginStoreRow.transaction do
      [*languages].each do |l|
        if update(l)
          updated.push(l['code'])
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
