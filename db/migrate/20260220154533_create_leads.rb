class CreateLeads < ActiveRecord::Migration[8.0]
  def change
    create_table :leads do |t|
      t.string :name
      t.string :status
      t.string :phone
      t.string :email
      t.decimal :budget
      t.integer :agent_id

      t.timestamps
    end

    add_index :leads, :agent_id
    add_index :leads, :status
  end
end
