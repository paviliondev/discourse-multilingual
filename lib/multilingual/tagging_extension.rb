module Multilingual::DiscourseTaggingExtension
  def filter_allowed_tags(guardian, opts = {})
    result = super
          
    if opts[:for_input]
      result.select { |tag| Multilingual::Languages.tag_names.exclude? tag.name }
    else
      result
    end
  end
  
  def tag_topic_by_names(topic, guardian, tag_names_arg, append: false)
    return false unless validate_require_language_tag(guardian, topic, tag_names_arg)
    super
  end
  
  def validate_require_language_tag(guardian, topic, tag_names)
    if SiteSetting.multilingual_enabled &&
       (SiteSetting.multilingual_require_language_tag === 'yes' ||
       (!guardian.is_staff? &&
         SiteSetting.multilingual_require_language_tag === 'non-staff')) &&
       (tag_names.blank? || 
         !Tag.where(name: tag_names)
            .where("id IN (
              #{DiscourseTagging::TAG_GROUP_TAG_IDS_SQL}
              AND tg.name = 'languages'
            )").exists?)

      topic.errors.add(:base,
       I18n.t(
         "tags.required_tags_from_group",
         count: 1,
         tag_group_name: 'language'
       )
      )
      false
    else
      true
    end
  end
end

class << DiscourseTagging
  prepend Multilingual::DiscourseTaggingExtension
end