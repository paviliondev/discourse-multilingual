# frozen_string_literal: true
require_relative '../../plugin_helper'

describe Multilingual::AdminTranslationsController do
  fab!(:admin_user) { Fabricate(:user, admin: true) }
  fab!(:tag1) { Fabricate(:tag, name: "pavilion") }
  fab!(:tag2) { Fabricate(:tag, name: "follow") }
  let(:custom_languages) { "#{Rails.root}/plugins/discourse-multilingual/spec/fixtures/custom_languages.yml" }
  let(:category_name_translation) { "#{Rails.root}/plugins/discourse-multilingual/spec/fixtures/category_name.wbp.yml" }
  let(:category_description_translation) { "#{Rails.root}/plugins/discourse-multilingual/spec/fixtures/category_description.wbp.yml" }
  let(:server_locale) { "#{Rails.root}/plugins/discourse-multilingual/spec/fixtures/server.wbp.yml" }
  let(:client_locale) { "#{Rails.root}/plugins/discourse-multilingual/spec/fixtures/client.fr.yml" }
  let(:tag_translation) { "#{Rails.root}/plugins/discourse-multilingual/spec/fixtures/tag.wbp.yml" }

  before(:all) do
    sign_in(admin_user)
    SiteSetting.multilingual_enabled = true
    SiteSetting.multilingual_content_languages_enabled = true
    Multilingual::CustomLanguage.create("wbp", name: "Warlpiri", run_hooks: true)
    Multilingual::Language.setup
    Multilingual::ContentTag.update_all
  end

  before(:each) do
    sign_in(admin_user)
    Multilingual::Cache.refresh!
  end

  it "uploads category name translation" do
    post '/admin/multilingual/translations.json', params: {
      file: Rack::Test::UploadedFile.new(category_name_translation)
    }
    expect(response.status).to eq(200)
    expect(Multilingual::CustomTranslation.by_type(["category_name"]).count).to eq(1)
    get '/admin/multilingual/translations.json'
    expect(response.status).to eq(200)
    parsed = response.parsed_body
    expect(parsed.first["locale"]).to eq ("wbp")
    expect(parsed.first["file_type"]).to eq ("category_name")
  end

  it "uploads category description translation" do
    post '/admin/multilingual/translations.json', params: {
      file: Rack::Test::UploadedFile.new(category_description_translation)
    }
    expect(response.status).to eq(200)
    expect(Multilingual::CustomTranslation.by_type(["category_description"]).count).to eq(1)
    get '/admin/multilingual/translations.json'
    expect(response.status).to eq(200)
    parsed = response.parsed_body
    expect(parsed.first["locale"]).to eq ("wbp")
    expect(parsed.first["file_type"]).to eq ("category_description")
  end

  it "uploads server locale" do
    post '/admin/multilingual/translations.json', params: {
      file: Rack::Test::UploadedFile.new(server_locale)
    }
    expect(response.status).to eq(200)
    expect(Multilingual::CustomTranslation.by_type(["server"]).count).to eq(1)
    I18n.locale = "wbp"
    expect(I18n.t 'topics').to eq("tematy")
    expect(I18n.t 'views.mountain').to eq("góry")
  end

  it "uploads client locale" do
    post '/admin/multilingual/translations.json', params: {
      file: Rack::Test::UploadedFile.new(client_locale)
    }
    expect(response.status).to eq(200)
    expect(Multilingual::CustomTranslation.by_type(["client"]).count).to eq(1)
    I18n.locale = "fr"
    expect(I18n.t ("js.filters.latest.title")).to eq("Wowah")

    delete '/admin/multilingual/translations.json', params: {
      file_type: "client", locale: "fr"
    }
    expect(response.status).to eq(200)
    expect(I18n.t ("js.filters.latest.title")).to eq("Récents")
  end

  it "uploads tag translation" do
    post '/admin/multilingual/translations.json', params: {
      file: Rack::Test::UploadedFile.new(tag_translation)
    }
    expect(response.status).to eq(200)
    expect(Multilingual::CustomTranslation.by_type(["tag"]).count).to eq(1)
  end
end
