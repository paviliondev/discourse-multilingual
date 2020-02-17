class ::Multilingual::TranslationFile
  include ActiveModel::Serialization
  
  TRANSLATION_PATH ||= "#{Multilingual::PLUGIN_PATH}/config/translations".freeze
  FILE_KEY ||= 'files'.freeze
    
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
    result = Hash.new
    
    processed = process(translations)
    result[:error] = processed[:error] if processed[:error]
    
    return result if result[:error]
    
    file = format(processed[:translations])
    
    File.open(path, 'w') { |f| f.write file.to_yaml }
    
    after_save
    
    result
  end
  
  def interface_file
    @type === :server || @type === :client
  end
  
  def remove
    if exists?
      File.delete(path)
      after_remove
    end
  end
  
  def after_save
    Multilingual::TranslationLocale.register(self) if interface_file
    after_all
  end
  
  def after_remove
    Multilingual::TranslationLocale.deregister(self) if interface_file
    after_all
  end
  
  def after_all
    Multilingual::Translation.refresh!
    Multilingual::Language.refresh!
    Multilingual.refresh_clients(@code)
  end
  
  def path
    TRANSLATION_PATH + "/#{filename}"
  end
  
  def filename
    "#{@type.to_s}.#{@code.to_s}.yml"
  end
  
  def process(translations)
    result = Hash.new
  
    if interface_file
      if translations.keys.length != 1
        result[:error] = "file format error"
      end
            
      if Multilingual::Language.all[translations.keys.first].blank?
        result[:error] = "language not supported"
      end
            
      if @type === :client && 
        (translations.values.first.keys + ['js', 'admin_js', 'wizard_js']).uniq.length != 3
        
        result[:error] = "file format error"
      end
    end
    
    return result if result[:error]
       
    translations.each do |key, translation|
      
      if @type === :tag && SiteSetting.multilingual_tag_translations_enforce_format
        translations[key] = DiscourseTagging.clean_tag(translation)
      end
    end
    
    result[:translations] = translations
    
    result
  end
  
  def format(content)
    file = Hash.new
    
    if @type == :tag
      ## Format to make it easier to integrate with JsLocaleHelper
      file[@code.to_s] = {
        "js" => {
          "_#{@type.to_s}" => content
        }
      }
    else
      file = content
    end
        
    file
  end
  
  def self.all
    Multilingual::Cache.wrap(FILE_KEY) do
      filenames.reduce([]) do |result, filename|
        opts = process_filename(filename)
        result.push(Multilingual::TranslationFile.new(opts)) if !opts[:error]
        result
      end
    end
  end
  
  def self.by_type(types)
    all.select { |f| [*types].map(&:to_sym).include?(f.type) }
  end
  
  def self.filenames
    Dir.entries(TRANSLATION_PATH)
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

    if result[:ext] != 'yml'
      result[:error] = "incorrect format"
    end
    
    result
  end
  
  def self.refresh!
    Multilingual::Cache.refresh(FILE_KEY)
  end
end