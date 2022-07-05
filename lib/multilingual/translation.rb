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
      result = Multilingual::CustomTranslation.where(file_type: type) || {}
    end
  end

  def self.is_custom(type)
    CUSTOM_TYPES.include?(type)
  end

  def self.get(type, keys = [])
    if is_custom(type)
      data = get_custom(type)

      return nil if data == {}

      result = {}
      data.each do |d|
        if type == 'category_name'

          yml_data = d["translation_data"]

          code = d["code"]

          this_result = look_for(yml_data, keys)

          result[code.to_sym] = this_result
        else
          code = d["code"]
          result[code.to_sym] = d["translation_data"]
        end
      end
      result
    end
  end

  def self.look_for(data, keys)
    return nil if data == {}
    if keys.first == data.first.first
      if data.first.last.is_a?(Hash)
        new_keys = keys.dup
        new_keys.shift
        if new_keys == [] then
          look_for(data.first.last, ["_"])
        else
          look_for(data.first.last, new_keys)
        end
      else
        data.first.last
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
