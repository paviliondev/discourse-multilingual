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
      result = {}
      Multilingual::TranslationFile.by_type(type).each do |f|
        result[f.code.to_s] = f.open
      end
      result
    end
  end

  def self.is_custom(type)
    CUSTOM_TYPES.include?(type)
  end

  def self.get(type, keys)
    if is_custom(type)
      data = get_custom(type)

      if type == 'category_name'
        result = {}
        data.each { |c, d| result[c] = recurse(d, keys.dup) }
        result
      else
        data[keys]
      end
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
    Multilingual::TranslationFile.load
    Multilingual::TranslationLocale.load
  end
end
