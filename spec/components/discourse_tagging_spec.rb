# frozen_string_literal: true

require_relative '../plugin_helper'

describe DiscourseTagging do
  fab!(:user) { Fabricate(:user) }
  fab!(:tag1) { Fabricate(:tag, name: "fun") }
  fab!(:tag2) { Fabricate(:tag, name: "fun2") }
  fab!(:tag3) { Fabricate(:tag, name: "Fun3") }

  before(:all) do
    SiteSetting.tagging_enabled = true
    SiteSetting.multilingual_enabled = true
    SiteSetting.multilingual_content_languages_enabled = true
    Multilingual::Cache.new(Multilingual::ContentTag::KEY).delete
    Multilingual::ContentTag.update_all
  end

  it "filter_allowed_tags for input fields doesn't include content language tags" do
    lang_tag = Tag.find_by(name: 'fr')
    topic = Fabricate(:topic, tags: [tag1, tag2, tag3, lang_tag])
    tags = DiscourseTagging.filter_allowed_tags(Guardian.new(user), for_input: true).map(&:name)

    expect(tags).not_to include(lang_tag.name)
  end

  it "works when the discourse tagging filter returns a context" do
    lang_tag = Tag.find_by(name: 'fr')
    topic = Fabricate(:topic, tags: [tag1, tag2, tag3, lang_tag])
    tags, context = DiscourseTagging.filter_allowed_tags(Guardian.new(user), for_input: true, with_context: true)

    expect(tags.map(&:name)).not_to include(lang_tag.name)
  end

  it "filter_visible result doesn't include content language tags" do
    lang_tag = Tag.find_by(name: 'fr')
    topic = Fabricate(:topic, tags: [tag1, tag2, tag3, lang_tag])
    tags = DiscourseTagging.filter_visible(topic.tags, Guardian.new(user))

    expect(tags.size).to eq(3)
    expect(tags).to contain_exactly(tag1, tag2, tag3)
  end
end
