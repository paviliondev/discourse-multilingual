# frozen_string_literal: true

require_relative '../../plugin_helper'

describe Multilingual::Language do
  before(:all) do
    SiteSetting.multilingual_enabled = true
    SiteSetting.multilingual_content_languages_enabled = true
    Multilingual::Language.setup
  end

  before(:each) do
    Multilingual::Cache.refresh!
  end

  context 'custom language' do
    before(:each) do
      Multilingual::CustomLanguage.create('abc', name: 'Custom Language', run_hooks: true)
    end

    context 'create' do
      it 'should create a new language record' do
        expect(Multilingual::Language.exists?('abc')).to eq(true)
      end

      it 'should update language record if language does exist' do
        Multilingual::CustomLanguage.create('abc', name: 'Custom Language 2.0', run_hooks: true)
        expect(Multilingual::Language.get('abc').first.name).to eq('Custom Language 2.0')
      end
    end

    context 'destroy' do
      it 'should destroy a language record' do
        Multilingual::CustomLanguage.destroy('abc', run_hooks: true)
        expect(Multilingual::Language.exists?('abc')).to eq(false)
      end

      it "should remove a langauge's exclusions" do
        Multilingual::Language.update(locale: 'abc', interface_enabled: false)
        Multilingual::CustomLanguage.destroy('abc', run_hooks: true)

        expect(
          Multilingual::LanguageExclusion.get(Multilingual::InterfaceLanguage::KEY, 'abc')
        ).to eq(false)
      end
    end

    context 'update' do
      it "should add to a language's exclusions" do
        Multilingual::Language.update({ locale: 'fr', interface_enabled: false }, run_hooks: true)
        expect(
          Multilingual::LanguageExclusion.get(Multilingual::InterfaceLanguage::KEY, 'fr')
        ).to eq(true)
      end

      it "should not exclude english" do
        Multilingual::Language.update({ locale: 'en', interface_enabled: false }, run_hooks: true)
        expect(
          Multilingual::LanguageExclusion.get(Multilingual::InterfaceLanguage::KEY, 'en')
        ).to eq(false)
      end

      it "should add to a custom language's exclusions" do
        Multilingual::Language.update({ locale: 'abc', interface_enabled: false }, run_hooks: true)
        expect(
          Multilingual::LanguageExclusion.get(Multilingual::InterfaceLanguage::KEY, 'abc')
        ).to eq(true)
      end

      it 'should add to both interface and content exclusions' do
        Multilingual::Language.update({ locale: 'fr', interface_enabled: false, content_enabled: false }, run_hooks: true)
        expect(
          Multilingual::LanguageExclusion.get(Multilingual::InterfaceLanguage::KEY, 'fr')
        ).to eq(true)
        expect(
          Multilingual::LanguageExclusion.get(Multilingual::ContentLanguage::KEY, 'fr')
        ).to eq(true)
      end

      it 'should remove exclusions' do
        Multilingual::Language.update({ locale: 'fr', interface_enabled: false }, run_hooks: true)
        expect(
          Multilingual::LanguageExclusion.get(Multilingual::InterfaceLanguage::KEY, 'fr')
        ).to eq(true)

        Multilingual::Language.update({ locale: 'fr', interface_enabled: true }, run_hooks: true)
        expect(
          Multilingual::LanguageExclusion.get(Multilingual::InterfaceLanguage::KEY, 'fr')
        ).to eq(false)
      end
    end
  end

  context 'get' do
    it 'should return a array containing one language when given a code' do
      result = Multilingual::Language.get('aa')
      expect(result.length).to eq(1)
      expect(result.first.locale).to eq('aa')
    end

    it 'should return an array of languages when given an array of codes' do
      result = Multilingual::Language.get(['aa', 'ab'])
      expect(result.map(&:locale)).to eq(['aa', 'ab'])
      expect(result.map(&:name)).to eq(['Afar', 'Abkhaz'])
    end
  end

  context 'all' do
    it 'should return all languages' do
      Multilingual::Cache.refresh!
      languages = Multilingual::Language.list
      expect(languages.length).to eq(187)
      expect(languages.first.locale).to eq('aa')
      expect(languages.first.name).to eq('Afar')
    end
  end

  context 'filter' do
    it 'should filter languages by code' do
      list = Multilingual::Language.filter(query: 'en')
      expect(list.length).to eq(9)
    end

    it 'should filter languages by name' do
      list = Multilingual::Language.filter(query: 'eng')
      expect(list.length).to eq(3)
    end

    it 'should order languages by code' do
      list = Multilingual::Language.filter(query: 'en', order: 'locale')
      expect(list.first.locale).to eq('ve')
    end

    it 'should reverse the order if ascending' do
      list = Multilingual::Language.filter(query: 'en', order: 'locale', ascending: true)
      expect(list.first.locale).to eq('bn')
    end

    it 'should order languages by name' do
      list = Multilingual::Language.filter(query: 'en', order: 'name', ascending: true)
      expect(list.first.locale).to eq('hy')
    end

    it 'should order languages by content enabled' do
      Multilingual::Language.update({ locale: 'sl', content_enabled: false }, run_hooks: true)
      result = Multilingual::Language.filter(query: 'en', order: 'content_enabled')
      expect(result.first.locale).to eq('sl')
    end

    it 'should order languages by interface enabled' do
      Multilingual::Language.update({ locale: 'ht', interface_enabled: false }, run_hooks: true)
      result = Multilingual::Language.filter(query: 'ht', order: 'interface_enabled', ascending: true)
      expect(result.first.locale).to eq('ht')
    end

    it 'should order languages by custom' do
      Multilingual::CustomLanguage.create('en2', name: 'English 2', run_hooks: true)
      result = Multilingual::Language.filter(query: 'en', order: 'custom', ascending: true)
      expect(result.first.locale).to eq('en2')
    end
  end

  context 'set_exclusion' do
    it 'should add content exclusions' do
      Multilingual::LanguageExclusion.set('fr', Multilingual::CustomLanguage::KEY, enabled: false)
      Multilingual::Cache.refresh!
      expect(
        Multilingual::LanguageExclusion.get(Multilingual::CustomLanguage::KEY, 'fr')
      ).to eq(true)
    end

    it 'should add interface exclusions' do
      Multilingual::LanguageExclusion.set('sl', Multilingual::InterfaceLanguage::KEY, enabled: false)
      Multilingual::Cache.refresh!
      expect(
        Multilingual::LanguageExclusion.get(Multilingual::InterfaceLanguage::KEY, 'sl')
      ).to eq(true)
    end

    it 'should remove exclusions' do
      Multilingual::LanguageExclusion.set('sv', Multilingual::InterfaceLanguage::KEY, enabled: false)
      Multilingual::Cache.refresh!
      Multilingual::LanguageExclusion.set('sv', Multilingual::InterfaceLanguage::KEY, enabled: true)
      Multilingual::Cache.refresh!
      expect(
        Multilingual::LanguageExclusion.get(Multilingual::InterfaceLanguage::KEY, 'sv')
      ).to eq(false)
    end
  end

  context 'bulk_create' do
    before(:each) do
      Multilingual::CustomLanguage.bulk_create(
        cus1: { name: "Custom Language 1" },
        cus2: { name: "Custom Language 2" }
      )
    end

    it 'should create custom languages' do
      expect(Multilingual::Language.list.map(&:locale)).to include("cus1")
      expect(Multilingual::Language.list.map(&:locale)).to include("cus2")
    end

    it 'should create content tags for the custom languages' do
      expect(Multilingual::ContentTag.exists?('cus1')).to equal(true)
      expect(Multilingual::ContentTag.exists?('cus2')).to equal(true)
    end
  end

  context 'bulk_update' do
    it 'should update languages' do
      Multilingual::Language.bulk_update([
        { locale: 'it', content_enabled: false },
        { locale: 'fr', interface_enabled: false }
      ])
      expect(Multilingual::LanguageExclusion.get(Multilingual::ContentLanguage::KEY, 'it')).to eq(true)
      expect(Multilingual::LanguageExclusion.get(Multilingual::InterfaceLanguage::KEY, 'fr')).to eq(true)
    end
  end

  context 'bulk_destroy' do
    before(:each) do
      Multilingual::CustomLanguage.bulk_create(
        cus1: { name: "Custom Language 1" },
        cus2: { name: "Custom Language 2" }
      )
      Multilingual::CustomLanguage.bulk_destroy(['cus1', 'cus2'])
    end

    it 'should destroy custom languages' do
      expect(Multilingual::Language.list.map(&:locale)).not_to include("cus1")
      expect(Multilingual::Language.list.map(&:locale)).not_to include("cus2")
    end

    it 'should destroy associated custom language tags' do
      expect(Multilingual::ContentTag.exists?('cus1')).to equal(false)
      expect(Multilingual::ContentTag.exists?('cus2')).to equal(false)
    end
  end
end
