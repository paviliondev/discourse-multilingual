# frozen_string_literal: true

require_relative '../plugin_helper'

describe TagGroup do

  before(:all) do
    SiteSetting.tagging_enabled = true
    SiteSetting.multilingual_enabled = true
    SiteSetting.multilingual_content_languages_enabled = true
  end

  it 'when enabled dont include special Tag Groups in list of visible Tag Groups' do
    anon_guardian = Guardian.new
    user_guardian = Guardian.new(Fabricate(:user))

    # Test only valid if there are exactly 2 groups that are special Multilingual Content Tag Groups
    expect(Multilingual::ContentTag.groups.count).to eq(2)

    expect(TagGroup.visible(anon_guardian)).not_to include(Multilingual::ContentTag.groups.first)
    expect(TagGroup.visible(anon_guardian)).not_to include(Multilingual::ContentTag.groups.second)
    expect(TagGroup.visible(user_guardian)).not_to include(Multilingual::ContentTag.groups.first)
    expect(TagGroup.visible(user_guardian)).not_to include(Multilingual::ContentTag.groups.second)
  end
end
