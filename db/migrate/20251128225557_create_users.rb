class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users do |t|
      t.string :uid, null: false
      t.string :name, null: false
      t.string :email, null: false
      t.string :image
      t.timestamps
    end

    add_index :users, [:uid, :email], unique: true
  end
end
