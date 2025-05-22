class ServiceContractsIssueQuery < IssueQuery

    belongs_to :service_contract
    class_attribute :service_contract

    def initialize(attributes=nil, *args)
        super attributes
        self.filters = {  }
    end

    def initialize_available_filters
        super
        delete_available_filter(:services_contract_number)
    end

    def statement
        filters_clauses = [super]
        filters_clauses << service_contract_statement
        filters_clauses.any? ? filters_clauses.join(' AND ') : nil
    end

    def service_contract_statement
        "(#{Issue.table_name}.id IN (SELECT #{ServiceContractsIssue.table_name}.issue_id FROM #{ServiceContractsIssue.table_name}
         WHERE #{ServiceContractsIssue.table_name}.service_contract_id = #{service_contract.id}))" if service_contract
    end

    def default_columns_names
        @default_columns_names ||= [ "id", "subject", "status","start_date","closed_on","services_contract_used_hours"].flat_map{|c| [c.to_s, c.to_sym]}
    end
end