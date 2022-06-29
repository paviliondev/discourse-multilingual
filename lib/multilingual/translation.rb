# frozen_string_literal: true
class Multilingual::Translation
  KEY ||= "translation"
  CORE_TYPES ||= %w{client server}
  CUSTOM_TYPES ||= %w{tag category_name}
  TYPES = CORE_TYPES + CUSTOM_TYPES

  def self.validate_type(type)
    TYPES.include?(type)
  end

  def self.get_custom(type)
    Multilingual::Cache.wrap("#{KEY}_#{type.to_s}") do
      result = Multilingual::CustomTranslation.find_by(file_type: type) || {}
    end
  end

  def self.is_custom(type)
    CUSTOM_TYPES.include?(type)
  end

  def self.get(type, keys)
    if is_custom(type)
      data = get_custom(type)

      if type == 'category_name'
        yml_data = JSON.parse data["yml"].gsub('=>', ':')

        code = data["code"]

        result = look_for(yml_data, keys)

        return { code => result }
      else
        JSON.parse data["yml"].gsub('=>', ':')
      end
    end
  end

  def self.look_for(data, keys)

    if keys.first == data.first.first
      if data.first.last.is_a?(Hash)
        new_keys = keys.dup
        new_keys.shift
        look_for(data.first.last, new_keys)
      else
        return data.first.last
      end
    else
      new_data = data.dup
      new_data.shift
      look_for(new_data, keys)
    end
  end

  def self.recurse(obj, keys)
    return nil if !obj
    k = keys.shift
    keys.empty? ? cast_value(obj[k]) : recurse(obj[k], keys)
  end

  def self.cast_value(val)
    return val if val.is_a?(String)
    return val["_"] if val.is_a?(Hash)
    nil
  end

  def self.setup
    Multilingual::CustomTranslation.load
    Multilingual::TranslationLocale.load
  end
end
