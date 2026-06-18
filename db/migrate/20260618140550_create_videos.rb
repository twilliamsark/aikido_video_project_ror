class CreateVideos < ActiveRecord::Migration[8.1]
  def change
    create_table :videos do |t|
      t.references :teacher, null: false, foreign_key: true
      t.string :title, null: false
      t.string :youtube_url, null: false
      t.string :youtube_video_id, null: false
      t.text :description_plain_text
      t.text :search_text

      t.timestamps
    end

    add_index :videos, :youtube_video_id
  end
end
