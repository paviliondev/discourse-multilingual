class ::Multilingual::Content
  include ActiveModel::Serialization
  
  attr_reader :code, :name
  
  EXCLUSION_KEY = 'content_exclusions'

  def initialize(code, name)
    @code = code
    @name = name
  end
  
  def self.get(language_codes)
    [*language_codes].map do |code|
      core_locale = ::LocaleSiteSetting.language_names[code]
      name = core_locale ? core_locale['nativeName'] : code
      self.new(code, name)
    end      
  end
  
  def self.all
    @@all ||= ::LocaleSiteSetting.language_names.select do |k, v|
      self.exclusions.exclude? k
    end.map do |k, v|
      Multilingual::Content.new(k, v['nativeName'])
    end
  end
  
  def self.exclusions
    @@exclusions ||= begin
      data = PluginStore.get(Multilingual::PLUGIN_NAME, EXCLUSION_KEY) || ''
      data ? data.split(',') : []
    end
  end
  
  def self.reload!
    @@exclusions = nil
    @@all = nil
  end
end