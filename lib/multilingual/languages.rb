class ::Multilingual::Languages
  include ActiveModel::Serialization
  
  attr_reader :code,
              :name
  
  def initialize(attrs = {})
    @code = attrs[:code]
    @name = attrs[:name]
  end
  
  def self.save(code, name)
    PluginStore.set('discourse-multilingual-languages', code, name)
  end
  
  def self.get(language_codes)
    PluginStoreRow.where("
      plugin_name = 'discourse-multilingual-languages' AND
      key IN (?)
    ", [*language_codes])
      .to_a
      .map do |r|
        Multilingual::Languages.new(code: r.key, name: r.value)
      end
  end
  
  def self.all
    PluginStoreRow.where("
      plugin_name = 'discourse-multilingual-languages'
    ").to_a
      .map do |r|
        Multilingual::Languages.new(code: r.key, name: r.value)
      end
  end
      
  def self.import
    source_url = SiteSetting.multilingual_language_source_url
    
    if source_url.present? && (raw_file = open(source_url))
      yml = YAML.safe_load(raw_file)
      languages = yml['languages']
      
      if languages.present?
        language_codes = []
        
        PluginStoreRow.transaction do
          languages.each do |code, data|
            self.save(code, data.last.encode("UTF-8"))
            language_codes.push(code)
          end
          
          add_language_tags(language_codes)
        end
      end
    end
  end
  
  def self.add_language_tags(language_codes)
    tag_group = TagGroup.find_by(name: 'languages')
    
    return false unless tag_group
    
    language_codes.each do |code|
      tag = Tag.find_by(name: code)

      if tag.blank?
        tag = Tag.new(name: code)
        tag.save
      end
      
      if tag.tag_groups.exclude?(tag_group)
        group_membership = TagGroupMembership.new(
          tag_id: tag.id,
          tag_group_id: tag_group.id
        )
        group_membership.save
      end
    end
  end
  
  def self.language_tags(topic)
    if topic.tags.any?
      [*Multilingual::Languages.get(topic.tags.map(&:name))].map(&:code)
    else
      []
    end
  end
end