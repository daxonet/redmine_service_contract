class CreateServiceContractsTrackers < ActiveRecord::Migration[5.2]
  def change
    create_table :service_contracts_trackers do |t|
      t.integer :service_contract_id
      t.integer :tracker_id
    end
  end
end
