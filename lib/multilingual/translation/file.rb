class ::Multilingual::TranslationFile
  include ActiveModel::Serialization
  
  BASE_PATH = "#{Rails.root}/plugins/discourse-multilingual/config/translations"
    
  attr_accessor :code, :type
    
  def initialize(opts)
    @code = opts[:code].to_sym
    @type = opts[:type].to_sym
  end
    
  def exists?
    self.class.all.map(&:code).include?(@code)
  end
  
  def open
    YAML.safe_load(File.open(path)) if exists?
  end
  
  def save(translations)
    save_result = Hash.new
    
    process_result = process_translations(translations)
    save_result[:error] = process_result[:error] if process_result[:error]
    
    return save_result if save_result[:error]
    
    file = format(process_result[:translations])
    File.open(path, 'w') { |f| f.write file.to_yaml }
    
    Multilingual::TranslationFile.reset!
    
    save_result
  end
  
  def remove
    if exists?
      File.delete(path)
      Multilingual::TranslationFile.reset!
    end
  end
  
  def path
    BASE_PATH + "/#{filename}"
  end
  
  def filename
    "#{@type.to_s}.#{@code.to_s}.yml"
  end
  
  def process_translations(translations) 
    result = Hash.new
       
    translations.each do |key, translation|
      
      ## Add any additional translation processing here
      
      if @type == :tag && SiteSetting.multilingual_tag_translations_enforce_formatting
        translations[key] = DiscourseTagging.clean_tag(translation)
      end
    end
    
    result[:translations] = translations
    
    result
  end
  
  def format(content)
    file = Hash.new
    
    if Multilingual::Translation::CLIENT_TYPES.include?(@type)
      
      ## Format to make it easier to integrate with JsLocaleHelper
      
      file[@code]['js']["_#{@type}"] = content
    else
      file = content
    end
    
    file
  end
  
  def self.all
    @all ||= filenames.reduce([]) do |result, filename|
      opts = process_filename(filename)
      result.push(Multilingual::TranslationFile.new(opts)) if !opts[:error]
      result
    end
  end
  
  def self.filenames
    Dir.entries(BASE_PATH)
  end
  
  def self.process_filename(filename)
    result = Hash.new
    parts = filename.split('.')
    result = {
      type: parts[0],
      code: parts[1],
      ext: parts[2]
    }
    
    if !Multilingual::Translation.validate_type(result[:type])
      result[:error] = 'invalid type'
    end
    
    if !Multilingual::Locale.supported.include?(result[:code])
      result[:error] = "locale not supported"
    end

    if result[:ext] != 'yml'
      result[:error] = "incorrect format"
    end
    
    result
  end
  
  def self.reset!
    @all = nil
    JsLocaleHelper.clear_cache!
  end
end