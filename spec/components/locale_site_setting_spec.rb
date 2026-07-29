# frozen_string_literal: true

require_relative "../plugin_helper"

describe LocaleSiteSetting do
  describe ".valid_value?" do
    it "accepts an empty locale list" do
      expect(described_class.valid_value?("")).to eq(true)
    end

    it "validates every locale in a list" do
      expect(described_class.valid_value?("en|fr")).to eq(true)
      expect(described_class.valid_value?("en|invalid")).to eq(false)
    end
  end
end
