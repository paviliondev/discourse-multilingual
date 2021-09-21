# frozen_string_literal: true
require_relative '../plugin_helper'

describe ApplicationController do
  before do
    SiteSetting.multilingual_enabled = true
    SiteSetting.allow_user_locale = true
    SiteSetting.multilingual_guest_language_switcher = "header"
    Multilingual::Language.setup
  end

  # Using /bootstrap.json because discourse/spec/requests/application_controller_spec.rb does
  it "allows locale to be set via query params" do
    get "/bootstrap.json?locale=fr"
    expect(response.status).to eq(200)
    expect(response.parsed_body['bootstrap']['locale_script']).to end_with("fr.js")
  end

  it "allows locale to be set via a cookie" do
    cookies[:discourse_locale] = "fr"
    get "/bootstrap.json"
    expect(response.status).to eq(200)
    expect(response.parsed_body['bootstrap']['locale_script']).to end_with("fr.js")
  end

  it "doesnt leak after requests" do
    cookies[:discourse_locale] = "fr"
    get "/bootstrap.json"
    expect(response.status).to eq(200)
    expect(response.parsed_body['bootstrap']['locale_script']).to end_with("fr.js")
    expect(I18n.locale.to_s).to eq(SiteSettings::DefaultsProvider::DEFAULT_LOCALE)
  end
end