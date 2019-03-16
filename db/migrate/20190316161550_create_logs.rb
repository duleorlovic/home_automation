class CreateLogs < ActiveRecord::Migration[5.2]
  def change
    create_table :logs do |t|
      t.string :text
      t.string :color
      t.timestamps null: false
    end
  end
end
