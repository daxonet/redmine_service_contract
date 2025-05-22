class CreateServiceContractsIssues < ActiveRecord::Migration[5.2]
  def change
    create_table :service_contracts_issues do |t|
      t.integer :service_contract_id
      t.integer :issue_id
      t.boolean :use_spent_hours
      t.float :hours
    end
  end
end
