class CreateMostClosedPulls < ActiveRecord::Migration
  def change
    create_table :most_closed_pulls do |t|
      t.string :user
      t.integer :pulls

      t.timestamps
    end
  end
end
