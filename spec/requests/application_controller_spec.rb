# frozen_string_literal: true
require_relative "../plugin_helper"

describe ApplicationController do
  before do
    SiteSetting.multilingual_enabled = true
    SiteSetting.allow_user_locale = true
    SiteSetting.multilingual_guest_language_switcher = "header"
    Multilingual::Language.setup
  end

  def locale_scripts(body)
    Nokogiri::HTML5
      .parse(body)
      .css('script[src*="assets/locales/"]')
      .map { |script| script.attributes["src"].value }
  end

  # Using /bootstrap.json because discourse/spec/requests/application_controller_spec.rb does
  it "allows locale to be set via query params" do
    get "/latest?locale=fr"
    expect(response.status).to eq(200)
    expect(locale_scripts(response.body)).to include("/assets/locales/fr.js")
  end

  it "allows locale to be set via a cookie" do
    get "/latest", headers: { Cookie: "discourse_locale=fr" }
    expect(response.status).to eq(200)
    expect(locale_scripts(response.body)).to include("/assets/locales/fr.js")
  end

  it "doesnt leak after requests" do
    get "/latest", headers: { Cookie: "discourse_locale=fr" }
    expect(response.status).to eq(200)
    expect(locale_scripts(response.body)).to include("/assets/locales/fr.js")
    expect(I18n.locale.to_s).to eq(SiteSettings::DefaultsProvider::DEFAULT_LOCALE)
  end
end
