# frozen_string_literal: true

describe SiteSerializer do
  fab!(:category) { Fabricate(:category) }
  fab!(:user) { Fabricate(:user, admin: false) }
  let(:guardian) { Guardian.new(user) }

  before_all do
    Site.clear_cache
  end

  after do
    Site.clear_cache
  end

  context "when plugin is enabled" do
    before do
      SiteSetting.multilingual_enabled = true
    end

    it "serializes without error when there are no translations but a set locale" do
      user.locale = "en_GB"
      serialized = described_class.new(Site.new(guardian), scope: guardian, root: false).as_json
      c1 = serialized[:categories].find { |c| c[:id] == category.id }
      expect(c1[:name]).to eq(category.name)
    end

    it "serializes without error when there are no translations and a nil locale" do
      user.locale = nil
      serialized = described_class.new(Site.new(guardian), scope: guardian, root: false).as_json
      c1 = serialized[:categories].find { |c| c[:id] == category.id }
      expect(c1[:name]).to eq(category.name)
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

  context "when plugin is disabled" do
    before do
      SiteSetting.multilingual_enabled = false
    end

    it "serializes Categories even when plugin is disabled" do
      serialized = described_class.new(Site.new(guardian), scope: guardian, root: false).as_json
      category_count = serialized[:categories].count
      expect(category_count).to eq(2)
    end

    it "it doesn't serialize names as translations when plugin is disabled" do
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

      expect(c1[:name]).to eq(category.name)
    end
  end
end
