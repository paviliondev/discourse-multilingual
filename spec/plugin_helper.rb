RSpec.configure do |config|
  config.around(:each) do |spec|
    if spec.metadata[:import_languages]
      SiteSetting.multilingual_enabled = true
      SiteSetting.multilingual_language_source_url = "http://languagesource.com/languages.yml"
      
      plugin_root = "#{Rails.root}/plugins/discourse-multilingual"
      languages_yml = File.open(
        "#{plugin_root}/spec/fixtures/multilingual/languages.yml"
      ).read
      
      stub_request(:get, /languagesource.com/).to_return(
        status: 200,
        body: languages_yml
      )
      
      Multilingual::Languages.import
    end
    
    spec.run
  end
end