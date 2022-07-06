# frozen_string_literal: true

class CreateCustomTranslations < ActiveRecord::Migration[5.2]
  def change
    create_table :custom_translations do |t|
      t.string "file_name", null: false
      t.string "file_type", null: false
      t.string "locale", null: false
      t.string "file_ext", null: false
      t.text "translation_data", null: false

      t.timestamps
    end
  end
end
