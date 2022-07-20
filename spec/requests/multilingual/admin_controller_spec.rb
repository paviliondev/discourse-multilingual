# frozen_string_literal: true
require_relative '../../plugin_helper'

describe Multilingual::AdminController do
  fab!(:admin_user) { Fabricate(:user, admin: true) }

  before(:all) do
    sign_in(admin_user)
  end

  it "returns the content_language_tag_group_id" do
    sign_in(admin_user)
    get "/admin/multilingual.json"
    expect(response.status).to eq(200)
    expect(response.parsed_body['content_language_tag_group_id']).to be_present
  end
end
