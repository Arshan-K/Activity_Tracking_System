class CreateActivities < ActiveRecord::Migration[8.0]
  def change
    create_table :activities do |t|
      t.references :lead, null: false, foreign_key: true
      t.integer :activity_type
      t.text :description
      t.string :performed_by
      t.string :previous_value
      t.string :new_value
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :activities, :activity_type
    add_index :activities, :metadata, using: :gin
    add_index :activities, :created_at
  end
end
