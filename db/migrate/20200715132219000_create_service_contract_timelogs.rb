class CreateServiceContractTimelogs < ActiveRecord::Migration[5.2]
  def up
    execute <<-SQL
      CREATE VIEW service_contract_timelogs AS
      SELECT
		time_entries.id as time_entry_id,
		time_entries.activity_id,
		time_entries.project_id,
		time_entries.issue_id,
		service_contracts_issues.service_contract_Id as service_contract_Id,
		time_entries.user_id,
		time_entries.spent_on,
		time_entries.hours,
		time_entries.comments
	FROM
		time_entries
	JOIN service_contracts_issues ON
		service_contracts_issues.issue_id = time_entries.issue_id
	WHERE
		service_contracts_issues.use_spent_hours = 1
	UNION ALL
	SELECT
		0 as time_entry_id,
		0 as activity_id,
		issues.project_id,
		issues.id as issue_id,
		service_contracts_issues.service_contract_Id as service_contract_Id,
		issues.author_id as user_id,
		issues.start_date as spent_on,
		service_contracts_issues.hours as hours,
		'' as comments
	FROM
		issues
	JOIN service_contracts_issues ON
		service_contracts_issues.issue_id = issues.id
	WHERE
		service_contracts_issues.use_spent_hours = 0
    SQL
  end

  def down
    execute <<-SQL
      DROP VIEW IF EXISTS service_contract_timelogs;
    SQL
  end
end
