# frozen_string_literal: true
module MultilingualTranslatorPostExtension
  def get_old_lang
    @custom_fields_orig.present? ? @custom_fields_orig[Multilingual::Translator.lang_field] : nil
  end

  def get_new_lang
    custom_fields[Multilingual::Translator.lang_field]
  end

  def update_lang(old_lang, new_lang)
    Multilingual::ContentTag.remove_from_topic(topic, old_lang)
    Multilingual::ContentTag.add_to_topic(topic, new_lang) if new_lang
    topic.save!
    MessageBus.publish("/topic/#{topic.id}", reload_topic: true)
  end

  def save_custom_fields(force = false)
    old_lang = get_old_lang if Multilingual::Translator.content_tag_sync_enabled

    super(force)

    if Multilingual::Translator.content_tag_sync_enabled
      new_lang = get_new_lang
      update_lang(old_lang, new_lang) if new_lang != old_lang
    end
  end
end
