# frozen_string_literal: true
require_relative '../../plugin_helper'

describe Multilingual::AdminLanguagesController do
  fab!(:admin_user) { Fabricate(:user, admin: true) }
  let(:custom_languages) { File.open("#{Rails.root}/plugins/discourse-multilingual/spec/fixtures/custom_languages.yml") }

  before(:all) do
    sign_in(admin_user)
    SiteSetting.multilingual_enabled = true
    SiteSetting.multilingual_content_languages_enabled = true
    Multilingual::Language.setup
    Multilingual::ContentTag.update_all
  end

  before(:each) do
    Multilingual::Cache.refresh!
  end

  it "lists languages" do
    get "/admin/multilingual/languages.json"
    expect(response.status).to eq(200)
    expect(response.parsed_body.length).to eq(187)
  end

  it "removes custom languages" do
    Multilingual::CustomLanguage.create('abc', name: 'Custom Language', run_hooks: true)

    delete "/admin/multilingual/languages.json", params: { locales: ['abc'] }
    expect(response.status).to eq(200)
    expect(Multilingual::Language.exists?('abc')).to eq(false)
  end

  it "updates languages" do
    Multilingual::Language.update({ locale: 'fr', interface_enabled: false, content_enabled: false }, run_hooks: true)

    put "/admin/multilingual/languages.json", params: { languages: [ { locale: 'fr', content_enabled: true } ] }
    expect(response.status).to eq(200)

    french = Multilingual::Language.get(['fr']).first
    expect(french.interface_enabled).to eq(false)
    expect(french.content_enabled).to eq(true)
  end

  it "uploads custom languages" do
    post '/admin/multilingual/languages.json', params: {
      file: fixture_file_upload(custom_languages)
    }
    expect(response.status).to eq(200)
    expect(Multilingual::Language.exists?('wbp')).to eq(true)
  end
end
