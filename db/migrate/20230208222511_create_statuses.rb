class CreateStatuses < ActiveRecord::Migration[7.0]
  def change
    create_table :statuses do |t|
      t.string :foreign_id
      t.string :url
      t.text :content
      t.datetime :published
      t.boolean :is_descendant, default: false
      t.json :data
      
      t.timestamps
    end
  end
end
