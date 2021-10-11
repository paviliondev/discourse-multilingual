# frozen_string_literal: true
module TagMultilingualExtension
  def top_tags(limit_arg: nil, category: nil, guardian: nil)
    tags = super(limit_arg: limit_arg, category: category, guardian: guardian)

    if Multilingual::ContentLanguage.enabled
      tags = tags.select { |tag| Multilingual::ContentTag.all.exclude? tag }
    end

    tags
  end
end
