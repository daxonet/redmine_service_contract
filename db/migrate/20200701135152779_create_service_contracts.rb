class CreateServiceContracts < ActiveRecord::Migration[5.2]
  def change
    create_table :service_contracts do |t|
      t.string :number, null: true
      t.string :subject, null: true
      t.date :from_date, null: true
      t.date :to_date, null: true
      t.boolean :default_use_spent_hours, null: true
      t.boolean :is_default, null: true
      t.boolean :closed, null: true
      t.float :warning_hours, null: true
      t.string :error_hours, null: true
      t.integer :project_id, null: false
      t.integer :author_id, null: false
      t.belongs_to :author
      t.belongs_to :project
      t.timestamps
    end
  end
end
