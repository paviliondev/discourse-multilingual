# frozen_string_literal: true
require_relative './../plugin_helper'

describe Multilingual::Translation do
  fab!(:tag1) { Fabricate(:tag, name: "pavilion") }
  fab!(:tag2) { Fabricate(:tag, name: "follow") }

  before(:all) do
    SiteSetting.multilingual_enabled = true
    SiteSetting.multilingual_content_languages_enabled = true
    Multilingual::CustomLanguage.create("wbp", name: "Warlpiri", run_hooks: true)
    Multilingual::Language.setup
    Multilingual::ContentTag.update_all
  end

  it "category names are available as a translation" do
    Multilingual::CustomTranslation.create(
      file_name: "category_name.wbp.yml",
      file_type: "category_name",
      locale: "wbp",
      file_ext: "yml",
      translation_data: { "welcome" => "pardu-pardu-mani", "clients" => "kalyardi", "knowledge" => { "_" => "milya-pinyi", "clients" => "kalyardi milya-pinyi" } }
    )
    expect(Multilingual::Translation.get("category_name", ["welcome"])).to eq({ wbp: "pardu-pardu-mani" })
    expect(Multilingual::Translation.get("category_name", ["knowledge", "clients"])).to eq({ wbp: "kalyardi milya-pinyi" })
    expect(Multilingual::Translation.get("category_name", ["knowledge"])).to eq({ wbp: "milya-pinyi" })
    expect(Multilingual::Translation.get("category_name", ["knowledge", "made up completely"])).to eq({ wbp: nil })
  end

  it "Untranslated sub-categories return nil" do
    Multilingual::CustomTranslation.create(
      file_name: "category_name.wbp.yml",
      file_type: "category_name",
      locale: "wbp",
      file_ext: "yml",
      translation_data: { "welcome" => "pardu-pardu-mani" }
    )
    expect(Multilingual::Translation.get("category_name", ["welcome", "made up completely"])).to eq({ wbp: nil })
  end

  it "category descriptions are available as a translation" do
    Multilingual::CustomTranslation.create(
      file_name: "category_description.wbp.yml",
      file_type: "category_description",
      locale: "wbp",
      file_ext: "yml",
      translation_data: { "welcome" => "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Egestas pretium aenean pharetra magna ac placerat vestibulum lectus mauris. Maecenas sed enim ut sem viverra aliquet eget sit amet. Sodales neque sodales ut etiam sit amet. Morbi quis commodo odio aenean sed adipiscing diam donec adipiscing.", "clients" => "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Eget aliquet nibh praesent tristique magna. Senectus et netus et malesuada fames. Sodales neque sodales ut etiam sit amet. Tellus mauris a diam maecenas sed enim ut sem.Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Eget aliquet nibh praesent tristique magna. Senectus et netus et malesuada fames. Sodales neque sodales ut etiam sit amet. Tellus mauris a diam maecenas sed enim ut sem.", "knowledge" => { "_" => "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Neque aliquam vestibulum morbi blandit. Libero id faucibus nisl tincidunt eget nullam non nisi. Ac odio tempor orci dapibus ultrices in. Vitae justo eget magna fermentum iaculis eu non.", "clients" => "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. In nisl nisi scelerisque eu ultrices. Sollicitudin tempor id eu nisl. Enim sit amet venenatis urna cursus eget nunc. Iaculis eu non diam phasellus vestibulum." } }
    )
    expect(Multilingual::CustomTranslation.by_type(["category_description"]).count).to eq(1)
    expect(Multilingual::Translation.get("category_description", ["welcome"])).to eq({ wbp: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Egestas pretium aenean pharetra magna ac placerat vestibulum lectus mauris. Maecenas sed enim ut sem viverra aliquet eget sit amet. Sodales neque sodales ut etiam sit amet. Morbi quis commodo odio aenean sed adipiscing diam donec adipiscing." })
    expect(Multilingual::Translation.get("category_description", ["knowledge", "clients"])).to eq({ wbp: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. In nisl nisi scelerisque eu ultrices. Sollicitudin tempor id eu nisl. Enim sit amet venenatis urna cursus eget nunc. Iaculis eu non diam phasellus vestibulum." })
    expect(Multilingual::Translation.get("category_description", ["knowledge"])).to eq({ wbp: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Neque aliquam vestibulum morbi blandit. Libero id faucibus nisl tincidunt eget nullam non nisi. Ac odio tempor orci dapibus ultrices in. Vitae justo eget magna fermentum iaculis eu non." })
  end

  it "when there are no uploaded tag translations, return empty hash" do
    expect(Multilingual::Translation.get("tag")).to eq({})
  end

  it "tags are available as a translation" do
    Multilingual::CustomTranslation.create(
      file_name: "tag.wbp.yml",
      file_type: "tag",
      locale: "wbp",
      file_ext: "yml",
      translation_data: { "pavilion" => "parnka", "follow" => "ngurra" }
    )
    expect(Multilingual::Translation.get("tag")).to eq({ wbp: { "pavilion" => "parnka", "follow" => "ngurra" } })
  end
end
