module MultilingualTranslatorPostExtension
  def translator_lang_field
    "DiscourseTranslator".constantize::DETECTED_LANG_CUSTOM_FIELD
  end
  
  def multilingual_translator_sync_enabled
    SiteSetting.multilingual_enabled &&
    SiteSetting.multilingual_translator_content_tag_sync
  end
  
  def save_custom_fields(force = false)
    if multilingual_translator_sync_enabled
      existing_lang = @custom_fields_orig.present? ? @custom_fields_orig[translator_lang_field] : nil
    end
        
    super(force)
    
    if multilingual_translator_sync_enabled
      new_lang = custom_fields[translator_lang_field]
            
      if new_lang != existing_lang
        Multilingual::ContentTag.remove_from_topic(topic, existing_lang)
        Multilingual::ContentTag.add_to_topic(topic, new_lang) if new_lang
        topic.save!
        MessageBus.publish("/topic/#{topic.id}", reload_topic: true)
      end
    end
  end
end