class CreateMostCommits < ActiveRecord::Migration
  def change
    create_table :most_commits do |t|
      t.string :user
      t.integer :commits

      t.timestamps
    end
  end
end
