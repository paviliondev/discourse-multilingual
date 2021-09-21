# frozen_string_literal: true

require_relative '../plugin_helper'

describe DiscourseTagging do
  fab!(:user) { Fabricate(:user) }
  fab!(:tag1) { Fabricate(:tag, name: "fun") }
  fab!(:tag2) { Fabricate(:tag, name: "fun2") }
  fab!(:tag3) { Fabricate(:tag, name: "Fun3") }
  fab!(:topic) { Fabricate(:topic, tags: [tag1, tag2, tag3, Tag.find_by(name: 'fr')]) }

  before(:all) do
    SiteSetting.multilingual_enabled = true
    SiteSetting.multilingual_content_languages_enabled = true
    Multilingual::Language.setup
  end

  it "filter_allowed_tags for input fields doesn't include content language tags" do
    tags = DiscourseTagging.filter_allowed_tags(Guardian.new(user),
      for_input: true,
    ).map(&:name)
    expect(tags).not_to include(Tag.find_by(name: 'fr').name)
  end
  
  it "filter_visible result doesn't include content language tags" do
    tags = DiscourseTagging.filter_visible(topic.tags, Guardian.new(user))
    expect(tags.size).to eq(3)
    expect(tags).to contain_exactly(tag1, tag2, tag3)
  end
end