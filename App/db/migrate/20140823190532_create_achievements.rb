class CreateAchievements < ActiveRecord::Migration
  def change
    create_table :achievements do |t|
      t.string :user
      t.string :repository
      t.string :achievement
      t.timestamp :achieved

      t.timestamps
    end
  end
end
