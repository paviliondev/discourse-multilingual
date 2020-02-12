class Multilingual::ContentTag
  NAME_KEY = 'content_tag_names'.freeze
  GROUP_NAME = 'languages'.freeze
  
  def self.create(code)
    unless Tag.exists?(name: code)
      tag = Tag.new(name: code)
      tag.save!
      
      membership = TagGroupMembership.new(
        tag_id: tag.id,
        tag_group_id: group.id
      )
      membership.save!
    end
  end
  
  def self.destroy(code)
    if exists?(code)
      Tag.where(name: code).destroy_all
    end
  end
  
  def self.names
    if names = Multilingual::Cache.read(NAME_KEY)
      names
    else
      names = Tag.where("id IN (
        #{DiscourseTagging::TAG_GROUP_TAG_IDS_SQL} AND 
        tg.name = '#{Multilingual::ContentTag::GROUP_NAME}'
      )").pluck(:name)
      Multilingual::Cache.write(NAME_KEY, names)
      names
    end
  end
  
  def self.exists?(name)
    self.names.include?(name)
  end
  
  def self.filter(tags)
    if tags.any?
      tags.select { |tag| names.include?(tag.name) }
    else
      []
    end
  end
  
  def self.group
    @group ||= begin
      group = TagGroup.find_by(name: Multilingual::ContentTag::GROUP_NAME)

      if group.blank?
        group = TagGroup.new(
          name: Multilingual::ContentTag::GROUP_NAME,
          permissions: { everyone: 1 }
        )

        group.save
      else
        group.permissions = { everyone: 1 }
        group.save
      end
      
      group
    end
  end
  
  def self.bulk_update_all
    Multilingual::Language.all.each do |l|
      bulk_update(l.code, l.content_enabled ? "create" : "destroy" )
    end
  end
  
  def self.bulk_update(codes, action)
    [*codes].each do |c|
      Multilingual::ContentTag.send(action, c)
    end
  end
  
  def self.add_to_topic(topic, tags)
    topic_tags = topic.tags
    
    content_language_tags = tags.reduce([]) do |result, tag_name|
      if self.exists?(tag_name) && topic_tags.map(&:name).exclude?(tag_name)
        result.push(Tag.find_by(name: tag_name)) 
      end
      
      result
    end
            
    if content_language_tags.any?
      topic.tags = topic_tags + content_language_tags 
      topic.custom_fields['content_languages'] = content_language_tags.map(&:name)
    end
        
    topic
  end
end