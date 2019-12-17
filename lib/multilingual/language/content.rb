class ::Multilingual::Content
  include ActiveModel::Serialization
  
  attr_reader :code, :name
  
  EXCLUSION_KEY = 'content_exclusions'.freeze

  def initialize(code, name)
    @code = code
    @name = name
  end
  
  def self.get(language_codes)
    [*language_codes].map do |code|
      locale = Multilingual::Base.list[code]
      name = locale ? locale['nativeName'] : code
      self.new(code, name)
    end      
  end
  
  def self.all
    @all ||= Multilingual::Base.list.select do |k, v|
      self.exclusions.exclude? k
    end.map do |k, v|
      Multilingual::Content.new(k, v)
    end
  end
  
  def self.exclusions
    @exclusions ||= begin
      data = PluginStore.get(Multilingual::PLUGIN_NAME, EXCLUSION_KEY) || ''
      data ? [*data.split(',')] : []
    end
  end
  
  def self.active?(code)
    self.exclusions.exclude?(code)
  end
  
  def self.reload!
    @exclusions = nil
    @all = nil
  end
end