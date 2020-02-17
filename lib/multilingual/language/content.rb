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
    Multilingual::Cache.wrap(CONTENT_KEY) do
      Multilingual::Language.all.select do |k, v|
        self.exclusions.exclude? k
      end.map { |k, v| self.new(k, v['nativeName']) }.sort_by(&:code)
    end
  end
  
  def self.exclusions
    Multilingual::Cache.wrap(EXCLUSION_KEY) do
      [*(PluginStore.get(Multilingual::PLUGIN_NAME, EXCLUSION_KEY) || '').split(',')]
    end
  end
  
  def self.enabled?(code)
    self.exclusions.exclude?(code)
  end
end