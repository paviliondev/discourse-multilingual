class ::Multilingual::Content
  include ActiveModel::Serialization
  
  attr_reader :code, :name
  
  CONTENT_KEY ||= 'content'.freeze
  EXCLUSION_KEY ||= 'content_exclusions'.freeze

  def initialize(code, name)
    @code = code
    @name = name
  end
  
  def self.all
    if content = Multilingual::Cache.read(CONTENT_KEY)
      content
    else
      content = Multilingual::Locale.all.select do |k, v|
        self.exclusions.exclude? k
      end.map do |k, v|
        Multilingual::Content.new(k, v)
      end.sort_by(&:code)
      Multilingual::Cache.write(CONTENT_KEY, content)
      content
    end
  end
  
  def self.exclusions
    if exclusions = Multilingual::Cache.read(EXCLUSION_KEY)
      exclusions
    else
      data = PluginStore.get(Multilingual::PLUGIN_NAME, EXCLUSION_KEY) || ''
      exclusions = data ? [*data.split(',')] : []
      Multilingual::Cache.write(EXCLUSION_KEY, exclusions)
      exclusions
    end
  end
  
  def self.enabled?(code)
    self.exclusions.exclude?(code)
  end
end