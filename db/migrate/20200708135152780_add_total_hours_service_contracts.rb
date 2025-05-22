class AddTotalHoursServiceContracts < ActiveRecord::Migration[5.2]
    def change
      add_column :service_contracts, :total_hours, :float
    end
end
  