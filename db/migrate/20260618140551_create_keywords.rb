class CreateKeywords < ActiveRecord::Migration[8.1]
  def change
    create_table :keywords do |t|
      t.string :name, null: false
      t.string :normalized_name, null: false

      t.timestamps
    end

    add_index :keywords, :normalized_name, unique: true
  end
end
