class Multilingual::Tag
  GROUP_NAME = 'languages'
  
  def self.create(code, group)
    tag = Tag.find_by(name: code)

    if tag.blank?
      tag = Tag.new(name: code)
      tag.save
    end
    
    if tag.tag_groups.exclude?(group)
      membership = TagGroupMembership.new(
        tag_id: tag.id,
        tag_group_id: group.id
      )
      membership.save
    end
  end
  
  def self.destroy(code)
    
  end
  
  def self.all
    Tag.where("id IN (
      #{DiscourseTagging::TAG_GROUP_TAG_IDS_SQL} AND 
      tg.name = '#{Multilingual::Tag::GROUP_NAME}'
    )")
  end
  
  def self.names
    @tag_names ||= all.pluck(:name)
  end
  
  def self.filter(topic)
    if topic.tags.any?
      topic.tags.select { |tag| @tag_names.include? tag.name }
    else
      []
    end
  end
  
  def self.group
    group = TagGroup.find_by(name: Multilingual::Tag::GROUP_NAME)

    if group.blank?
      group = TagGroup.new(
        name: Multilingual::Tag::GROUP_NAME,
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