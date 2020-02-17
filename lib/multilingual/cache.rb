class Multilingual::Cache
  def self.write(key, data)
    Discourse.cache.write("#{Multilingual::PLUGIN_NAME}_#{key}", data)
  end
  
  def self.read(key)
    Discourse.cache.read("#{Multilingual::PLUGIN_NAME}_#{key}")
  end
  
  def self.delete(key)
    Discourse.cache.delete("#{Multilingual::PLUGIN_NAME}_#{key}")
  end
  
  def self.wrap(key, &block)
    if cached = read(key)
      cached
    else
      result = block.call()
      write(key, result)
      result
    end
  end
  
  def self.refresh(keys)
    [*keys].each { |key| self.delete(key) }
  end
end