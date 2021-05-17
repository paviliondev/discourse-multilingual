# frozen_string_literal: true

require 'rails_helper'

describe Multilingual::ContentTag do
  fab!(:tag1) { Fabricate(:tag, name: "tag1") }
  
  before(:all) do
    SiteSetting.multilingual_enabled = true
    SiteSetting.multilingual_content_languages_enabled = true
    Multilingual::ContentTag.bulk_update(['aa'], 'enable')
    Multilingual::ContentTag.update_all
  end
  
  it 'should create tags' do
    language_tag = Tag.find_by(name: 'aa')
    expect(language_tag.present?).to eq(true)
    expect(language_tag.tag_groups.first.id).to eq(
      TagGroup.where(name: Multilingual::ContentTag::GROUP).first.id
    )
  end
  
  it "should filter topic tags" do
    Tag.find_by(name: 'aa')
    topic = Fabricate(:topic, tags: [tag1, Tag.find_by(name: 'aa')])
    expect(Multilingual::ContentTag.filter(topic.tags).map(&:name)).to include('aa')
  end
end