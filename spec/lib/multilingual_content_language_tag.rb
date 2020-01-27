# frozen_string_literal: true

require 'rails_helper'

describe Multilingual::ContentTag do
  fab!(:tag1) { Fabricate(:tag, name: "tag1") }
  fab!(:tag2) { Fabricate(:tag, name: "tag2") }
  fab!(:topic) { 
    language_tag1 = Tag.find_by(name: 'aa')
    language_tag2 = Tag.find_by(name: 'am')
    Fabricate(:topic, tags: [tag1, tag2, language_tag1, language_tag2]) 
  }
  
  before(:all) do
    SiteSetting.multilingual_enabled = true
  end
  
  it 'should create tags' do
    Multilingual::ContentTag.create('aa')
    
    language_tag = Tag.where(name: 'aa')
    
    expect(language_tag.exists?).to eq(true)
    expect(language_tag.first.tag_groups.first.id).to eq(
      TagGroup.where(name: Multilingual::ContentTag::GROUP).first.id
    )
  end
  
  it "should filter topic tags" do
    expect(Multilingual::ContentTag.filter(topic.tags).map(&:name)).to eq(['aa','am'])
  end
end