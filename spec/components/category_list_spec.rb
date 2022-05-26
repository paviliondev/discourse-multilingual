# frozen_string_literal: true

require_relative '../plugin_helper'

describe CategoryList do
  fab!(:user) { Fabricate(:user) }

  before(:all) do
    SiteSetting.tagging_enabled = true
    SiteSetting.multilingual_enabled = true
    SiteSetting.multilingual_content_languages_enabled = true

    Multilingual::Cache.new(Multilingual::ContentTag::KEY).delete
    Multilingual::ContentTag.update_all

    @cat1 = Fabricate(:category_with_definition)
    @cat2 = Fabricate(:category_with_definition)
    Fabricate(:topic, category: @cat1, tags: [Tag.find_by(name: 'fr')])
    Fabricate(:topic, category: @cat2)

    CategoryFeaturedTopic.feature_topics
  end

  it "only shows content language topics if content language topic filtering is enabled" do
    SiteSetting.multilingual_content_languages_topic_filtering_enabled = true

    expect(CategoryList.new(Guardian.new(user), include_topics: true).categories.find { |x| x.name == @cat1.name }.displayable_topics.count).to eq(1)
    expect(CategoryList.new(Guardian.new(user), include_topics: true).categories.find { |x| x.name == @cat2.name }.displayable_topics.count).to eq(0)
  end

  it "shows all topics if content language topic filtering is not enabled" do
    SiteSetting.multilingual_content_languages_topic_filtering_enabled = false

    expect(CategoryList.new(Guardian.new(user), include_topics: true).categories.find { |x| x.name == @cat1.name }.displayable_topics.count).to eq(1)
    expect(CategoryList.new(Guardian.new(user), include_topics: true).categories.find { |x| x.name == @cat2.name }.displayable_topics.count).to eq(1)
  end
end
