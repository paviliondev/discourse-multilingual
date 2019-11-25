# frozen_string_literal: true

require 'rails_helper'

describe Multilingual::Languages do
  before(:all) do
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

  describe 'import' do
    it 'should import languages into plugin store' do      
      expect(PluginStoreRow.where("
        plugin_name = 'discourse-multilingual-languages'
      ").length).to eq(23)
    end
    
    it 'should encode and store language names correctly' do
      name = PluginStoreRow.where("
        plugin_name = 'discourse-multilingual-languages' AND
        key = ?
      ", 'aa').first.value
      
      expect(name.encoding.to_s).to eq('UTF-8')
      expect(name).to eq("Qafár af")
    end
    
    it 'should create tags in the languages tag group' do
      language_tag = Tag.where(name: 'aa')
      
      expect(language_tag.exists?).to eq(true)
      expect(language_tag.first.tag_groups.first.id).to eq(
        TagGroup.where(name: 'languages').first.id
      )
    end
  end
  
  describe 'language_tags' do
    fab!(:tag1) { Fabricate(:tag, name: "tag1") }
    fab!(:tag2) { Fabricate(:tag, name: "tag2") }
    fab!(:topic) { 
      language_tag1 = Tag.find_by(name: 'aa')
      language_tag2 = Tag.find_by(name: 'am')
      Fabricate(:topic, tags: [tag1, tag2, language_tag1, language_tag2]) 
    }
    
    it "should return list of language tags" do
      expect(Multilingual::Languages.language_tags(topic)).to eq(['aa','am'])
    end
  end
  
  describe 'all' do
    it 'should return a formatted list of languages' do
      languages = Multilingual::Languages.all
      expect(languages.length).to eq(23)
      expect(languages.first.code).to eq('aa')
      expect(languages.first.name).to eq('Qafár af')
    end
  end
  
  describe 'get' do
    it 'should return a formatted language' do
      language = Multilingual::Languages.get('aa')
      expect(language.first.code).to eq('aa')
    end
    
    it 'should accept an array of language codes' do
      languages = Multilingual::Languages.get(['aa','am'])
      expect(languages.map(&:code)).to eq(['aa','am'])
      expect(languages.map(&:name)).to eq(['Qafár af','አማርኛ'])
    end
  end
end
