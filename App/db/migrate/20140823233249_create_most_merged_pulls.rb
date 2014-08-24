class CreateMostMergedPulls < ActiveRecord::Migration
  def change
    create_table :most_merged_pulls do |t|
      t.string :user
      t.integer :pulls

      t.timestamps
    end
  end
end
