require 'rails_helper'
require 'topic_view'

describe TopicQuery, import_languages: true do
  context "user has content languages" do
    fab!(:user1) { Fabricate(:user) }
    fab!(:user2) { Fabricate(:user) }
    
    fab!(:tag1) { Fabricate(:tag, name: "tag1") }
    fab!(:tag2) { Fabricate(:tag, name: "tag2") }
    
    fab!(:language_topic1) {
      language_tag1 = Tag.find_by(name: 'aa')
      Fabricate(:topic, tags: [tag1, language_tag1]) 
    }
    
    fab!(:language_topic2) {
      language_tag2 = Tag.find_by(name: 'am')
      Fabricate(:topic, tags: [language_tag2]) 
    }
    
    fab!(:non_language_topic1) { Fabricate(:topic, tags: [tag1]) }
    fab!(:non_language_topic2) { Fabricate(:topic, tags: [tag2]) }
    
    it "filters topic list properly" do
      user1.custom_fields['content_languages'] = ['aa', 'am']
      user1.save_custom_fields(true)
      
      expect(TopicQuery.new(user1).list_latest.topics.count).to eq(2)
      expect(TopicQuery.new(user2).list_latest.topics.count).to eq(4)
    end
  end
end