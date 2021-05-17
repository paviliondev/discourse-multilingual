# frozen_string_literal: true
module TopicSerializerMultilingualExtension
  def tags
    result = super
    result = result - content_language_tags if Multilingual::ContentLanguage.enabled
    result
  end
end
