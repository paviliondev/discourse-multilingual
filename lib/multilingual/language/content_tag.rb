class Multilingual::ContentTag
  KEY = 'content_tag'.freeze
  GROUP = 'content_languages'.freeze
  GROUP_DISABLED = 'content_languages_disabled'.freeze
  QUERY = "#{DiscourseTagging::TAG_GROUP_TAG_IDS_SQL} AND tg.name = '#{GROUP}'"
  
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
  
  def self.enabled_group
    @enabled_group ||= begin
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
  
  def self.disabled_group
    @disabled_group ||= begin
      group = TagGroup.find_by(name: Multilingual::ContentTag::GROUP_DISABLED)

      if group.blank?
        group = TagGroup.new(
          name: Multilingual::ContentTag::GROUP_DISABLED,
          permissions: { staff: 3 }
        )

        group.save!
      else
        group.permissions = { staff: 3 }
        group.save!
      end
      
      group
    end
  end
  
  def self.groups
    [GROUP,GROUP_DISABLED]
  end
  
  QUERY_ALL = "
    #{DiscourseTagging::TAG_GROUP_TAG_IDS_SQL}
    AND tg.name IN (#{groups.map{|g|"'#{g}'"}.join(',')})
  "
  
  def self.destroy_all
    Tag.where("id in (#{QUERY})").destroy_all
    Multilingual::Cache.new(KEY).delete
  end
  
  def self.enqueue_update_all
    Jobs.enqueue(:update_content_language_tags)
  end
  
  def self.update_all
    if Multilingual::ContentLanguage.enabled
      enable = []
      disable = []
      
      Multilingual::Language.list.each do |l|
        if l.content_enabled
          enable.push(l.code) if all.exclude?(l.code)
        else
          disable.push(l.code) if all.include?(l.code)
        end
      end
      
      bulk_update(enable, "enable") if enable.any?
      bulk_update(disable, "destroy") if disable.any?
      
      Multilingual::Cache.new(KEY).delete
    end
  end
  
  def self.bulk_update(codes, action)
    groups = []
    tags = []
    
    [*codes].each do |code|
      is_new = false
      tag = Tag.find_by(name: code)
      
      if !tag
        tag = Tag.new(name: code)
        is_new = true
      end
      
      if !is_new && enabled_group.tags.exclude?(tag) && disabled_group.tags.exclude?(tag)
        ## tag already exists, so we don't interfere with it
        Multilingual::LanguageExclusion.set(tag.name, 'content_language', enabled: false)  
      else  
        group = self.send("#{action}d_group")
        group.tags << tag unless group.tags.include?(tag)
        tag.tag_groups = [group]
        
        tags.push(tag) unless tags.include?(tag)
        groups.push(group) unless groups.include?(group)
      end
    end
    
    Tag.transaction do
      tags.each { |tag| tag.save! }      
      groups.each { |group| group.save! }
    end
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
    topic.tags = (tags + ctags.select { |t| tags.map(&:id).exclude?(t.id) }).uniq {|t| t.id }
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