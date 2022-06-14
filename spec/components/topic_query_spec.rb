# frozen_string_literal: true

require_relative '../plugin_helper'

describe TopicQuery do
  before(:all) do
    SiteSetting.tagging_enabled = true
    SiteSetting.multilingual_enabled = true
    SiteSetting.multilingual_content_languages_enabled = true

    Multilingual::Cache.new(Multilingual::ContentTag::KEY).delete
    Multilingual::ContentTag.update_all
  end

  context "user has content languages" do
    fab!(:user1) { Fabricate(:user) }
    fab!(:user2) { Fabricate(:user) }
    fab!(:user3) { Fabricate(:user) }
    fab!(:tag1) { Fabricate(:tag, name: "tag1") }
    fab!(:tag2) { Fabricate(:tag, name: "tag2") }

    fab!(:language_topic1) {
      tag1 = Tag.find_by(name: 'tag1')
      language_tag1 = Tag.find_by(name: Multilingual::ContentTag.all.first)
      Fabricate(:topic, tags: [tag1, language_tag1])
    }

    fab!(:language_topic2) {
      language_tag2 = Tag.find_by(name: Multilingual::ContentTag.all.second)
      Fabricate(:topic, tags: [language_tag2])
    }

    fab!(:language_topic3) {
      language_tag3 = Tag.find_by(name: Multilingual::ContentTag.all.select { |t| t.include?("_") && t.downcase != t }.first)
      Fabricate(:topic, tags: [language_tag3])
    }

    fab!(:non_language_topic1) {
      tag1 = Tag.find_by(name: 'tag1')
      Fabricate(:topic, tags: [tag1])
    }
    fab!(:non_language_topic2) {
      tag2 = Tag.find_by(name: 'tag2')
      Fabricate(:topic, tags: [tag2])
    }

    before do
      user1.custom_fields['content_languages'] = [Multilingual::ContentTag.all.first, Multilingual::ContentTag.all.second]
      user1.save_custom_fields(true)
      user3.custom_fields['content_languages'] = [Multilingual::ContentTag.all.first, Multilingual::ContentTag.all.second, Multilingual::ContentTag.all.select { |t| t.include?("_") && t.downcase != t }.first]
      user3.save_custom_fields(true)
    end

    it "filters topic list when content language topic filtering is enabled" do
      SiteSetting.multilingual_content_languages_topic_filtering_enabled = true

      expect(TopicQuery.new(user1).list_latest.topics.count).to eq(2)
      expect(TopicQuery.new(user2).list_latest.topics.count).to eq(5)
    end

    it "does not filter topic list when content language topic filtering is disabled" do
      SiteSetting.multilingual_content_languages_topic_filtering_enabled = false

      expect(TopicQuery.new(user1).list_latest.topics.count).to eq(5)
      expect(TopicQuery.new(user2).list_latest.topics.count).to eq(5)
      expect(TopicQuery.new(user2).list_latest.topics.count).to eq(5)
    end

    it "filters topic list when content language topic filtering is enabled and includes content tags with capitalisation" do
      SiteSetting.multilingual_content_languages_topic_filtering_enabled = true

      expect(TopicQuery.new(user3).list_latest.topics.count).to eq(3)
    end

  end
end
