module Multilingual
  PLUGIN_NAME ||= 'discourse-multilingual-languages'.freeze
  
  class Language
    include ActiveModel::Serialization
    attr_reader :code, :name
    
    def initialize(relation)
      @code = relation.key
      @name = relation.value
    end
    
    def self.save(code, name)
      PluginStore.set(PLUGIN_NAME, code, name)
    end
    
    def self.get(language_codes)
      serializable(PluginStoreRow.where("
        plugin_name = '#{PLUGIN_NAME}' AND
        key IN (?)
      ", [*language_codes]))
    end
    
    def self.all
      serializable(PluginStoreRow.where("
        plugin_name = '#{PLUGIN_NAME}'
      "))
    end
    
    def self.serializable(relation)
      relation.to_a.map { |r| self.new(r) }
    end
  end

  class Languages
    class << self
      def tag_names
        @tag_names ||= Tag.where("id IN (
          #{DiscourseTagging::TAG_GROUP_TAG_IDS_SQL} AND 
          tg.name = 'languages'
        )").pluck(:name)
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
              Multilingual::Language.save(code, data.last.encode("UTF-8"))
              language_codes.push(code)
            end
            
            add_tags(language_codes)
          end
        end
      end
    end
    
    def self.add_tags(language_codes)
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
      
      @tag_names = language_codes
    end
    
    def self.tags_for(topic)
      if topic.tags.any?
        topic.tags.select { |tag| @tag_names.include? tag.name }
      else
        []
      end
    end
  end
end