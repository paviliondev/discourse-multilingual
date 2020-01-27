class ::Multilingual::Content
  include ActiveModel::Serialization
  
  attr_reader :code, :name
  
  EXCLUSION_KEY = 'content_exclusions'.freeze

  def initialize(code, name)
    @code = code
    @name = name
  end
  
  def self.all
    @all ||= Multilingual::Locale.all.select do |k, v|
      self.exclusions.exclude? k
    end.map do |k, v|
      Multilingual::Content.new(k, v)
    end.sort_by(&:code)
  end
  
  def self.exclusions
    @exclusions ||= begin
      data = PluginStore.get(Multilingual::PLUGIN_NAME, EXCLUSION_KEY) || ''
      data ? [*data.split(',')] : []
    end
  end
  
  def self.enabled?(code)
    self.exclusions.exclude?(code)
  end
  
  def self.reload!
    @exclusions = nil
    @all = nil
  end
end