class CreateTemperatures < ActiveRecord::Migration[5.2]
  def change
    create_table :temperatures do |t|
      t.string :sensor
      t.float :celsius
      t.timestamps null: false
    end

    add_index       :temperatures, :sensor
  end
end
