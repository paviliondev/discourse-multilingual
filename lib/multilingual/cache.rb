class Multilingual::Cache
  def initialize(key)
    @key = "#{Multilingual::PLUGIN_NAME}_#{key}"
  end
  
  def write(data)
    synchronize { cache.write(@key, data) }
  end
  
  def read
    synchronize { cache.read(@key) }
  end
  
  def delete
    synchronize { cache.delete(@key) }
  end
  
  def synchronize
    DistributedMutex.synchronize("#{Multilingual::PLUGIN_NAME}_cache") { yield }
  end
  
  def cache
    @cache ||= Discourse.cache
  end
  
  def self.wrap(key, &block)
    c = Multilingual::Cache.new(key)
    
    if cached = c.read
      cached
    else
      result = block.call()
      c.write(result)
      result
    end
  end
  
  def self.refresh(keys)
    [*keys].each { |key| Multilingual::Cache.new(key).delete }
  end
end