# frozen_string_literal: true

class CreateCustomTranslations < ActiveRecord::Migration[5.2]
  def change
    create_table :custom_translations do |t|
      t.string "file", null: false
      t.string "file_type", null: false
      t.string "code", null: false
      t.string "ext", null: false
      t.text "yml", null: false

      t.timestamps
    end
  end
end
