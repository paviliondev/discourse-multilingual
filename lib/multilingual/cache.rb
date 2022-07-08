# frozen_string_literal: true
class Multilingual::Cache
  class << self
    attr_accessor :state
    attr_accessor :listable_classes
  end

  def self.load_classes
    %w[
      custom_translation
      content_tag
      content_tag/conflict
      language_exclusion
      custom_language
      language
      content_language
      interface_language
    ].each do |klass|
      class_name = "Multilingual::#{klass.classify}".constantize
      @listable_classes ||= []
      @listable_classes.push(class_name) if @listable_classes.exclude?(class_name)
    end
  end

  def self.setup
    load_classes
  end

  def initialize(key)
    @key = "#{Multilingual::PLUGIN_NAME}_#{key}"
  end

  def read
    cache.read(@key)
  end

  def write(data)
    synchronize { cache.write(@key, data) }
  end

  def delete
    synchronize { cache.delete(@key) }
  end

  def synchronize
    DistributedMutex.synchronize(@key) { yield }
  end

  def cache
    @cache ||= Discourse.cache
  end

  def self.wrap(key, &block)
    c = Multilingual::Cache.new(key)

    if (@state != 'changing') && (cached = c.read)
      cached
    else
      result = block.call()
      c.write(result)
      result
    end
  end

  def self.clear_core_caches!
    JsLocaleHelper.clear_cache!
    ExtraLocalesController.clear_cache!
    Site.clear_anon_cache!
  end

  def self.reload_i18n!
    I18n.config.backend.reload!
    I18n.reload!
  end

  def self.reset_core(opts = {})
    LocaleSiteSetting.reset!
    clear_core_caches!
  end

  def self.instantiate_core(opts = {})
    if opts[:action] === :remove && (I18n.locale.to_s === opts[:locale].to_s)
      I18n.locale = SiteSettings::DefaultsProvider::DEFAULT_LOCALE
    end

    if opts[:action] === :save && (I18n.locale.to_s != opts[:locale].to_s)
      I18n.locale = opts[:locale]
      I18n.load_locale(opts[:locale])
    end

    reload_i18n! if opts[:reload_i18n]
  end

  def self.reset
    self.load_classes if @listable_classes == nil
    @listable_classes.each { |klass| Multilingual::Cache.new(klass::KEY).delete }

    Multilingual::Translation::CUSTOM_TYPES.each do |type|
      Multilingual::Cache.new("#{Multilingual::Translation::KEY}_#{type}").delete
    end
  end

  def self.instantiate
    @listable_classes.each do |klass|
      if klass.respond_to?(:add_locale_to_cache)
      # klass.send(:add_locale_to_cache)
      else
        klass.send(:all) if klass.respond_to?(:all)
      end
    end
    @state = 'cached'
  end

  def self.refresh!(opts = {})
    reset
    reset_core(opts)
    instantiate
    instantiate_core(opts)
  end

  def self.refresh_clients(locales)
    locales = [*locales].map(&:to_s)
    changing_default = locales.include?(SiteSetting.default_locale.to_s)
    user_ids = nil

    if !changing_default && SiteSetting.allow_user_locale
      user_ids = User.where(locale: locales).pluck(:id)
    end
    if changing_default || user_ids.present?
      Discourse.request_refresh!(user_ids: user_ids)
    end
  end
end
