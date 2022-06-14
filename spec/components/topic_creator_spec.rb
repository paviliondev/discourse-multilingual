# frozen_string_literal: true

require_relative '../plugin_helper'

describe TopicCreator do
  fab!(:staff) { Fabricate(:moderator) }
  fab!(:user)  { Fabricate(:user) }
  fab!(:tag)  { Fabricate(:tag) }

  let(:valid_attrs) { Fabricate.attributes_for(:topic) }
  let(:message) { 'hello' }

  SiteSetting.tagging_enabled = true
  SiteSetting.multilingual_enabled = true
  SiteSetting.multilingual_content_languages_enabled = true

  Multilingual::ContentTag.update_all

  context 'when a language tag is required' do
    before(:each) do
      SiteSetting.multilingual_require_content_language_tag = 'yes'
    end

    context "when no language tag is present" do
      before do
        topic = Topic.new
        errors = ActiveModel::Errors.new(topic)
        Topic.stubs(:new).returns(topic)
        topic.stubs(:errors).returns(errors)
        errors.expects(:add).with(:base, "You must include at least 1 topic language.")
      end

      it "should rollback with a sensible error when no tags are present" do
        expect do
          TopicCreator.create(user, Guardian.new(user), valid_attrs)
        end.to raise_error(ActiveRecord::Rollback)
      end

      it "should rollback with a sensible error when only non language tags are present" do
        expect do
          TopicCreator.create(user, Guardian.new(user), valid_attrs.merge(tags: [tag.name]))
        end.to raise_error(ActiveRecord::Rollback)
      end
    end

    it "should work when a language tag is present" do
      attrs = valid_attrs.merge(content_language_tags: [Multilingual::ContentTag.all.first])
      topic = TopicCreator.create(user, Guardian.new(user), attrs)
      expect(topic).to be_valid
      expect(topic.tags.count).to eq(1)
    end

    it "should work when a language tag and a non language tag is present" do
      attrs = valid_attrs.merge(content_language_tags: [tag.name, Multilingual::ContentTag.all.first])
      topic = TopicCreator.create(user, Guardian.new(user), attrs)
      expect(topic).to be_valid
    end

    it "should work when a language tag contains an underscore and capitalised characters" do
      attrs = valid_attrs.merge(content_language_tags: [Multilingual::ContentTag.all.select { |t| t.include?("_") && t.downcase != t }.first])
      topic = TopicCreator.create(user, Guardian.new(user), attrs)

      expect(topic).to be_valid
      expect(topic.tags.count).to eq(1)
    end

    context 'when staff are exempt' do
      before(:each) do
        SiteSetting.multilingual_require_content_language_tag = 'non-staff'
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
      SiteSetting.multilingual_require_content_language_tag = 'no'
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
