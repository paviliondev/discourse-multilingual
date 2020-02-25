class Multilingual::ContentTag
  KEY = 'content_tag'.freeze
  GROUP = 'content_languages'.freeze
  QUERY = "#{DiscourseTagging::TAG_GROUP_TAG_IDS_SQL} AND tg.name = '#{GROUP}'"
  
  def self.create(code)
    tag = Tag.find_by(name: code)
    
    if !tag
      tag = Tag.new(name: code)
      tag.save!
    end
      
    unless TagGroupMembership.exists?(tag_id: tag.id, tag_group_id: group.id)
      membership = TagGroupMembership.new(
        tag_id: tag.id,
        tag_group_id: group.id
      )
      membership.save!
    end
  end
  
  def self.destroy(code)
    Tag.where(name: code).destroy_all if exists?(code)
  end
  
  def self.all
    Multilingual::Cache.wrap(KEY) do
      Tag.where("id in (#{QUERY})").pluck(:name)
    end
  end
  
  def self.exists?(name)
    self.all.include?(name)
  end
  
  def self.filter(tags)
    if tags.any?
      tags.select { |tag| all.include?(tag.name) }
    else
      []
    end
  end
  
  def self.group
    @group ||= begin
      group = TagGroup.find_by(name: Multilingual::ContentTag::GROUP)

      if group.blank?
        group = TagGroup.new(
          name: Multilingual::ContentTag::GROUP,
          permissions: { everyone: 1 }
        )

        group.save!
      else
        group.permissions = { everyone: 1 }
        group.save!
      end
      
      group
    end
  end
  
  def self.destroy_all
    Tag.where("id in (#{QUERY})").destroy_all
    Multilingual::Cache.new(KEY).delete
  end
  
  def self.enqueue_update_all
    Jobs.enqueue(:update_content_language_tags)
  end
  
  def self.update_all
    if Multilingual::ContentLanguage.enabled
      create = []
      destroy = []
      
      Multilingual::Language.list.each do |l|
        if l.content_enabled
          create.push(l.code) if all.exclude?(l.code)
        else
          destroy.push(l.code) if all.include?(l.code)
        end
      end

      bulk_update(create, "create") if create.any?
      bulk_update(destroy, "destroy") if destroy.any?
      
      Multilingual::Cache.new(KEY).delete
    end
  end
  
  def self.bulk_update(codes, action)
    [*codes].each { |c| Multilingual::ContentTag.send(action, c) }
  end
  
  def self.load(ctag_names)
    [*ctag_names].map { |t| t.underscore }
      .reduce([]) do |result, name|
        result.push(Tag.find_by(name: name)) if self.exists?(name)
        result
      end
  end
  
  def self.update_topic(topic, ctag_names = [])
    ctags = ctag_names.any? ? load(ctag_names) : []
    tags = topic.tags.select { |t| self.all.exclude?(t.name) }
    topic.tags = tags + ctags 
    topic.custom_fields['content_languages'] = ctags.any? ? ctags.map(&:name) : []
    topic
  end
  
  def self.remove_from_topic(topic, ctag_name)
    update_topic(topic, (topic.content_languages - [ctag_name]).uniq)
  end
  
  def self.add_to_topic(topic, ctag_name)
    update_topic(topic, (topic.content_languages + [ctag_name]).uniq)
  end
end