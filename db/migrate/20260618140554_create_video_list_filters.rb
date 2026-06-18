class CreateVideoListFilters < ActiveRecord::Migration[8.1]
  def change
    create_table :video_list_filters do |t|
      t.references :teacher, null: false, foreign_key: true
      t.string :name, null: false
      t.string :query
      t.string :sort_key, null: false, default: "newest"
      t.text :description_plain_text

      t.timestamps
    end
  end
end
