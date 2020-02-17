# frozen_string_literal: true

require 'rails_helper'

describe Multilingual::Language do
  before(:all) do
    SiteSetting.multilingual_enabled = true
    Multilingual::Language.setup
  end
  
  before(:each) do
    Multilingual::Language.refresh!
  end
  
  context 'custom language' do
    before(:each) do
      Multilingual::Language.create('abc', 'Custom Language')
    end
    
    context 'create' do
      it 'should create a new language record' do
        expect(
          PluginStore.get(Multilingual::PLUGIN_NAME, "#{Multilingual::Language::CUSTOM_KEY}_abc")
        ).to eq('Custom Language')
      end
      
      it 'should update language record if language does exist' do
        Multilingual::Language.create('abc', 'Custom Language 2.0')
        expect(
          PluginStore.get(Multilingual::PLUGIN_NAME, "#{Multilingual::Language::CUSTOM_KEY}_abc")
        ).to eq('Custom Language 2.0')
      end
    end
    
    context 'destroy' do      
      it 'should destroy a language record' do
        Multilingual::Language.destroy('abc')
        expect(
          PluginStore.get(Multilingual::PLUGIN_NAME, "#{Multilingual::Language::CUSTOM_KEY}_abc")
        ).to eq(nil)
      end
      
      it "should remove a lanauge's exclusions" do
        Multilingual::Language.update(code: 'abc', interface_enabled: false)
        Multilingual::Language.destroy('abc')
        expect(Multilingual::Interface.exclusions).not_to include('abc')
      end
    end
    
    context 'update' do      
      it "should add to a language's exclusions" do
        Multilingual::Language.update(code: 'en', interface_enabled: false)
        expect(Multilingual::Interface.exclusions).to include('en')
      end
      
      it "should add to a custom language's exclusions" do
        Multilingual::Language.update(code: 'abc', interface_enabled: false)
        expect(Multilingual::Interface.exclusions).to include('abc')
      end
      
      it 'should add to both interface and content exclusions' do
        Multilingual::Language.update(code: 'en', interface_enabled: false, content_enabled: false)
        expect(Multilingual::Interface.exclusions).to include('en')
        expect(Multilingual::Content.exclusions).to include('en')
      end
      
      it 'should remove exclusions' do
        Multilingual::Language.update(code: 'en', content_enabled: false)
        expect(Multilingual::Content.exclusions).to include('en')
        
        Multilingual::Language.update(code: 'en', content_enabled: true)
        expect(Multilingual::Content.exclusions).not_to include('en')
      end
    end
  end
  
  context 'get' do
    it 'should return a array containing one language when given a code' do
      result = Multilingual::Language.get('aa')
      expect(result.length).to eq(1)
      expect(result.first.code).to eq('aa')
    end
    
    it 'should return an array of languages when given an array of codes' do
      result = Multilingual::Language.get(['aa','ab'])
      expect(result.map(&:code)).to eq(['aa','ab'])
      expect(result.map(&:name)).to eq(['Afaraf','аҧсуа бызшәа'])
    end
  end
  
  context 'all' do
    it 'should return all languages' do
      Multilingual::Language.refresh!
      languages = Multilingual::Language.list
      expect(languages.length).to eq(187)
      expect(languages.first.code).to eq('aa')
      expect(languages.first.name).to eq('Afaraf')
    end
  end
  
  context 'filter' do
    it 'should filter languages by code' do
      result = Multilingual::Language.filter(query: 'en')
      expect(result.length).to eq(10)
    end
    
    it 'should filter languages by name' do
      result = Multilingual::Language.filter(query: 'eng')
      expect(result.length).to eq(2)
    end
    
    it 'should order languages by code' do
      result = Multilingual::Language.filter(query: 'en', order: 'code')
      expect(result.first.code).to eq('ve')
    end
    
    it 'should reverse the order if ascending' do
      result = Multilingual::Language.filter(query: 'en', order: 'code', ascending: true)
      expect(result.first.code).to eq('en')
    end
    
    it 'should order languages by name' do
      result = Multilingual::Language.filter(query: 'en', order: 'name')
      expect(result.first.code).to eq('is')
    end
    
    it 'should order languages by content enabled' do
      Multilingual::Language.update(code: 'sl', content_enabled: false)
      result = Multilingual::Language.filter(query: 'en', order: 'content_enabled')
      expect(result.first.code).to eq('sl')
    end
    
    it 'should order languages by interface enabled' do
      Multilingual::Language.update(code: 'ht', interface_enabled: false)
      result = Multilingual::Language.filter(query: 'en', order: 'interface_enabled')
      expect(result.first.code).to eq('ht')
    end
    
    it 'should order languages by custom' do
      Multilingual::Language.create('en2', 'English 2')
      result = Multilingual::Language.filter(query: 'en', order: 'custom', ascending: true)
      
      expect(result.first.code).to eq('en2')
    end
  end
  
  context 'set_exclusion' do    
    it 'should add content exclusions' do
      Multilingual::Language.set_exclusion('en', 'content', false)
      Multilingual::Language.refresh!
      expect(Multilingual::Content.exclusions).to include('en')
    end
    
    it 'should add interface exclusions' do
      Multilingual::Language.set_exclusion('sl', 'interface', false)
      Multilingual::Language.refresh!
      expect(Multilingual::Interface.exclusions).to include('sl')
    end
    
    it 'should remove exclusions' do
      Multilingual::Language.set_exclusion('sv', 'interface', false)
      Multilingual::Language.refresh!
      Multilingual::Language.set_exclusion('sv', 'interface', true)
      Multilingual::Language.refresh!
      expect(Multilingual::Interface.exclusions).not_to include('sv')
    end
  end
  
  context 'bulk_create' do
    before(:each) do
      Multilingual::Language.bulk_create(cus1: "Custom Language 1", cus2: "Custom Language 2")
    end
    
    it 'should create custom languages' do
      expect(Multilingual::Language.list.map(&:code)).to include("cus1")
      expect(Multilingual::Language.list.map(&:code)).to include("cus2")
    end
    
    it 'should create content tags for the custom languages' do
      expect(Multilingual::ContentTag.exists?('cus1')).to equal(true)
      expect(Multilingual::ContentTag.exists?('cus2')).to equal(true)
    end
  end
  
  context 'bulk_update' do
    it 'should update languages' do
      Multilingual::Language.bulk_update([{code: 'en', content_enabled: false},{code: 'fr', interface_enabled: false}])
      expect(Multilingual::Content.exclusions).to include('en')
      expect(Multilingual::Interface.exclusions).to include('fr')
    end
  end
  
  context 'bulk_destroy' do
    before(:each) do
      Multilingual::Language.bulk_create(cus1: "Custom Language 1", cus2: "Custom Language 2")
      Multilingual::Language.bulk_destroy(['cus1','cus2'])
    end
    
    it 'should destroy custom languages' do
      expect(Multilingual::Language.list.map(&:code)).not_to include("cus1")
      expect(Multilingual::Language.list.map(&:code)).not_to include("cus2")
    end
    
    it 'should destroy associated custom language tags' do
      expect(Multilingual::ContentTag.exists?('cus1')).to equal(false)
      expect(Multilingual::ContentTag.exists?('cus2')).to equal(false)
    end
  end
end
