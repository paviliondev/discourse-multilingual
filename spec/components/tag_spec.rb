# frozen_string_literal: true

require_relative "../plugin_helper"

describe Tag do
  fab!(:tag1) { Fabricate(:tag, name: "fun") }
  fab!(:tag2) { Fabricate(:tag, name: "fun2") }
  fab!(:public_category) { Fabricate(:category) }

  before do
    SiteSetting.tagging_enabled = true
    SiteSetting.multilingual_enabled = true
    SiteSetting.multilingual_content_languages_enabled = true

    Multilingual::Cache.new(Multilingual::ContentTag::KEY).delete
    Multilingual::ContentTag.update_all
  end

  it "top_tags doesn't include content language tags" do
    Fabricate(:topic, category: public_category, tags: [tag1, tag2, Tag.find_by(name: "fr")])
    expect(
      Tag.top_tags(category: public_category, guardian: Guardian.new(Fabricate(:user))),
    ).not_to include(Tag.find_by(name: "fr").name)
  end
end
