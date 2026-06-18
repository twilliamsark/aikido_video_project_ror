class CreateVideoKeywords < ActiveRecord::Migration[8.1]
  def change
    create_table :video_keywords do |t|
      t.references :video, null: false, foreign_key: true
      t.references :keyword, null: false, foreign_key: true

      t.timestamps
    end

    add_index :video_keywords, [ :video_id, :keyword_id ], unique: true
  end
end
