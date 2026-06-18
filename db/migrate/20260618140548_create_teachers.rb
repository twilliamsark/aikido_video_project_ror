class CreateTeachers < ActiveRecord::Migration[8.1]
  def change
    create_table :teachers do |t|
      t.string :email_address, null: false
      t.string :password_digest, null: false

      t.timestamps
    end

    add_index :teachers, :email_address, unique: true
  end
end
