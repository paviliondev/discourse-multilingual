# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "language tagging" do
  fab!(:staff) { Fabricate(:moderator) }
  fab!(:user)  { Fabricate(:user) }
  fab!(:tag)  { Fabricate(:tag) }
  fab!(:topic) { Fabricate(:topic, title: 'Topic title', custom_fields: {}) }
  
  let(:valid_attrs) { Fabricate.attributes_for(:topic) }
  let(:language_tag_name) { Tag.where(name: Multilingual::Language.tag_names).first.name }
  
  let(:message) { 'hello' }

  before do
    SiteSetting.tagging_enabled = true
    SiteSetting.multilingual_enabled = true
    SiteSetting.multilingual_language_source_url = "http://languagesource.com/languages.yml"
    
    plugin_root = "#{Rails.root}/plugins/discourse-multilingual"
    languages_yml = File.open(
      "#{plugin_root}/spec/fixtures/multilingual_languages.yml"
    ).read
    
    stub_request(:get, /languagesource.com/).to_return(
      status: 200,
      body: languages_yml
    )
    
    Multilingual::Language.import
  end

  context 'when required to add language tag' do
    before(:each) do
      SiteSetting.multilingual_require_language_tag = 'yes'
    end
    
    it "should rollback when no tags are present" do    
      expect do
        TopicCreator.create(user, Guardian.new(user), valid_attrs)
      end.to raise_error(ActiveRecord::Rollback)
    end
    
    it "should rollback when only non language tags are present" do
      expect do
        TopicCreator.create(user, Guardian.new(user), valid_attrs.merge(tags: [tag.name]))
      end.to raise_error(ActiveRecord::Rollback)
    end
    
    it "should work when a language tag is present" do
      topic = TopicCreator.create(user, Guardian.new(user), valid_attrs.merge(tags: [language_tag_name]))
      expect(topic).to be_valid
    end
    
    it "should work when a language tag and a non language tag is present" do
      topic = TopicCreator.create(user, Guardian.new(user), valid_attrs.merge(tags: [tag.name, language_tag_name]))
      expect(topic).to be_valid
    end
    
    it "returns the correct error no language tag is present" do
      valid = DiscourseTagging.tag_topic_by_names(topic, Guardian.new(user), [tag.name])
      expect(valid).to eq(false)
      expect(topic.errors[:base]&.first).to eq(I18n.t(
        "tags.required_tags_from_group",
        count: 1,
        tag_group_name: 'language'
      ))
    end
    
    context 'when staff are exempt' do
      before(:each) do
        SiteSetting.multilingual_require_language_tag = 'non-staff'
      end
      
      it "should work when user is staff and no language tag is present" do
        topic = TopicCreator.create(staff, Guardian.new(staff), valid_attrs.merge(tags: [tag.name]))
        expect(topic).to be_valid
      end
      
      it "should rollback when user is not staff and no language tag is present" do
        expect do
          TopicCreator.create(user, Guardian.new(user), valid_attrs.merge(tags: [tag.name]))
        end.to raise_error(ActiveRecord::Rollback)
      end
    end
  end
  
  context 'when no language tag is required' do
    before(:each) do
      SiteSetting.multilingual_require_language_tag = 'no'
    end
    
    it "should work when no tags are present" do
      topic = TopicCreator.create(user, Guardian.new(user), valid_attrs)
      expect(topic).to be_valid
    end
    
    it "should work when no language tag is present" do
      topic = TopicCreator.create(user, Guardian.new(user), valid_attrs.merge(tags: [tag.name]))
      expect(topic).to be_valid
    end
  end
end