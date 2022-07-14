# frozen_string_literal: true

describe SiteSerializer do
  fab!(:user) { Fabricate(:user, admin: false) }
  let(:guardian) { Guardian.new(user) }
  let(:category) { Fabricate(:category) }

  after do
    Site.clear_cache
  end

  it "serializes names as translations" do
    Multilingual::CustomTranslation.create(
      file_name: "category_name.wbp.yml",
      file_type: "category_name",
      locale: "wbp",
      file_ext: "yml",
      translation_data: { category.slug => "pardu-pardu-mani" }
    )
    user.locale = "wbp"
    serialized = described_class.new(Site.new(guardian), scope: guardian, root: false).as_json
    c1 = serialized[:categories].find { |c| c[:id] == category.id }

    expect(c1[:name]).to eq("pardu-pardu-mani")
  end

  it "doesn't explode when user locale is nil" do
    Multilingual::CustomTranslation.create(
      file_name: "category_name.wbp.yml",
      file_type: "category_name",
      locale: "wbp",
      file_ext: "yml",
      translation_data: { category.slug => "pardu-pardu-mani" }
    )
    user.locale = nil
    serialized = described_class.new(Site.new(guardian), scope: guardian, root: false).as_json
    c1 = serialized[:categories].find { |c| c[:id] == category.id }

    expect(c1[:name]).to eq(category.name)
  end
end
