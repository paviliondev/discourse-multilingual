# frozen_string_literal: true
class Multilingual::Translation
  KEY ||= "translation"
  CORE_TYPES ||= %w{client server}
  CUSTOM_TYPES ||= %w{tag category_name category_description}
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

      return {} if data == {}

      result = {}
      data.each do |d|
        if ['category_name', 'category_description'].include? (type)

          yml_data = d["translation_data"]

          locale = d["locale"]

          this_result = look_for(yml_data, keys)

          result[locale.to_sym] = this_result
        else
          locale = d["locale"]
          result[locale.to_sym] = d["translation_data"]
        end
      end
      result
    end
  end

  def self.look_for(data, keys)
    return nil if data == {} || !keys.present?
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
        if keys.count == 1
          data.first.last
        else
          nil
        end
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
end
