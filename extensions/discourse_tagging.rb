# frozen_string_literal: true
module DiscourseTaggingMultilingualExtension
  def filter_allowed_tags(guardian, opts = {})
    result = super(guardian, opts)

    if opts[:for_input] && Multilingual::ContentLanguage.enabled
      tags_with_counts = opts[:with_context] ? result.first : result
      tags_with_counts = tags_with_counts.select { |tag| Multilingual::ContentTag.all.exclude? tag.name }
      result = opts[:with_context] ? [tags_with_counts, result.second] : tags_with_counts
    end

    result
  end

  def filter_visible(query, guardian = nil)
    result = super(query, guardian)

    if Multilingual::ContentLanguage.enabled
      result = result.where("tags.id NOT IN (#{Multilingual::ContentTag::QUERY_ALL})")
    end

    result
  end
end
