class CreateVideoListFilterShares < ActiveRecord::Migration[8.1]
  def change
    create_table :video_list_filter_shares do |t|
      t.references :teacher, null: false, foreign_key: true
      t.references :video_list_filter, null: false, foreign_key: true, index: { unique: true }
      t.string :token, null: false
      t.boolean :active, null: false, default: true
      t.datetime :shared_at
      t.datetime :unshared_at

      t.timestamps
    end

    add_index :video_list_filter_shares, :token, unique: true
    add_index :video_list_filter_shares, :active
  end
end
