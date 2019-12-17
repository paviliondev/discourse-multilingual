class Multilingual::Tag
  GROUP_NAME = 'languages'.freeze
  
  def self.create(code)
    unless exists?(code)
      tag = Tag.new(name: code)
      tag.save!
      
      membership = TagGroupMembership.new(
        tag_id: tag.id,
        tag_group_id: group.id
      )
      membership.save
    end
  end
  
  def self.destroy(code)
    if exists?(code)
      Tag.where(name: code).destroy_all
    end
  end
  
  def self.names
    @names ||= Tag.where("id IN (
      #{DiscourseTagging::TAG_GROUP_TAG_IDS_SQL} AND 
      tg.name = '#{Multilingual::Tag::GROUP_NAME}'
    )").pluck(:name)
  end
  
  def self.reload!
    @names = nil
  end
  
  def self.exists?(name)
    names.include?(name)
  end
  
  def self.filter(topic)
    if topic.tags.any?
      topic.tags.select { |tag| names.include?(tag.name) }
    else
      []
    end
  end
  
  def self.group
    @group ||= begin
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
end