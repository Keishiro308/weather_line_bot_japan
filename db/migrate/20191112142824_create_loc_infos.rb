class CreateLocInfos < ActiveRecord::Migration[5.2]
  def change
    create_table :loc_infos do |t|
      t.float :long
      t.float :lat
      t.integer :pref_id
      t.integer :city_id

      t.timestamps
    end
  end
end
