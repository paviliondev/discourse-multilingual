# frozen_string_literal: true
class Multilingual::ContentTag
  KEY = 'content_tag'.freeze
  GROUP = 'content_languages'.freeze
  GROUP_DISABLED = 'content_languages_disabled'.freeze
  QUERY = "#{DiscourseTagging::TAG_GROUP_TAG_IDS_SQL} AND tg.name IN ('#{GROUP}','#{GROUP_DISABLED}')"

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
    [GROUP, GROUP_DISABLED]
  end

  QUERY_ALL = "
    #{DiscourseTagging::TAG_GROUP_TAG_IDS_SQL}
    AND tg.name IN (#{groups.map { |g|"'#{g}'" }.join(',')})
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
          enable.push(l.locale) if all.exclude?(l.locale)
        else
          disable.push(l.locale) if all.include?(l.locale)
        end
      end

      bulk_update(enable, "enable") if enable.any?
      bulk_update(disable, "disable") if disable.any?

      Multilingual::Cache.new(KEY).delete
    end
  end

  def self.bulk_update(locales, action)
    tag_groups = []
    tags = []

    [*locales].each do |locale|
      is_new = false
      tag = Tag.find_by(name: locale)

      if !tag
        tag = Tag.new(name: locale)
        is_new = true
      end

      if !is_new && enabled_group.tags.exclude?(tag) && disabled_group.tags.exclude?(tag)
        Multilingual::Cache.new(Conflict::KEY).delete
      else
        tag_group = self.send("#{action}d_group")
        tag_group.tags << tag unless tag_group.tags.include?(tag)

        other_tag_group = self.send("#{action === 'enable' ? 'disable' : 'enable' }d_group")
        other_tag_group.tags.delete(tag) if other_tag_group.tags.include?(tag)

        tags.push(tag) unless tags.include?(tag)
        tag_groups.push(tag_group) unless tag_groups.include?(tag_group)
        tag_groups.push(other_tag_group) unless tag_groups.include?(other_tag_group)
      end
    end

    Tag.transaction do
      tags.each { |tag| tag.save! }
      tag_groups.each { |tag_group| tag_group.save! }
    end
  end

  def self.bulk_destroy(locales)
    Tag.where("id in (#{QUERY}) and name in (?)", locales).destroy_all
    Multilingual::Cache.new(KEY).delete
  end

  def self.load(ctag_names)
    [*ctag_names]
      .reduce([]) do |result, name|
      result.push(Tag.find_by(name: name)) if self.exists?(name)
       result
    end
  end

  def self.update_topic(topic, ctag_names = [])
    ctags = ctag_names.any? ? load(ctag_names) : []
    tags = topic.tags.select { |t| self.all.exclude?(t.name) }
    topic.tags = (tags + ctags.select { |t| tags.map(&:id).exclude?(t.id) }).uniq { |t| t.id }
    topic.custom_fields['content_languages'] = ctags.any? ? ctags.map(&:name) : []
    topic
  end

  def self.remove_from_topic(topic, ctag_name)
    update_topic(topic, (topic.content_languages - [ctag_name]).uniq)
  end

  def self.add_to_topic(topic, ctag_name)
    update_topic(topic, (topic.content_languages + [ctag_name]).uniq)
  end

  class Conflict
    KEY = 'content_tag_conflict'

    def self.all_uncached
      Tag.where("id not in (#{QUERY}) and name in (?)", Multilingual::Language.all.keys).pluck(:name)
    end

    def self.all
      Multilingual::Cache.wrap(Conflict::KEY) { all_uncached }
    end

    def self.exists?(locale)
      all.include?(locale)
    end
  end
end
